#!/usr/bin/env pwsh
param(
    [string]$LocalSubmodulePath,
    [string]$AdoOrg,
    [string]$AdoProject,
    [string]$AdoRepo,
    [string]$TargetBranch,
    [object]$TemplateReplacements = @{},
    [bool]$ForceSync = $false,
    [string[]]$IncludeSubfolders = @()  # Optional: specific subfolders to sync (e.g., @("modules", "scripts"))
)

# Set error handling
$ErrorActionPreference = 'Stop'

function Invoke-TemplateReplacement {
    param(
        [string]$SourceDirectory,
        [object]$ReplacementConfigs,
        [string]$Encoding = "utf8",
        [bool]$BackupOriginals = $false
    )

    Write-Output "INFO: Starting template replacement processing..."

    if (-not $ReplacementConfigs -or $ReplacementConfigs.Count -eq 0) {
        Write-Output "INFO: No template replacements configured, skipping"
        return
    }

    $totalContentReplacements = 0
    $totalNameReplacements = 0
    $filesProcessed = 0
    $directoriesRenamed = 0

    foreach ($configKey in $ReplacementConfigs.Keys) {
        $config = $ReplacementConfigs[$configKey]
        Write-Output "INFO: Processing replacement group: $configKey"

        $filePatterns = if ($config.file_patterns) { $config.file_patterns } else { @() }
        $directoryPatterns = if ($config.directory_patterns) { $config.directory_patterns } else { @() }
        $contentReplacements = if ($config.content_replacements) { $config.content_replacements } else { @{} }
        $nameReplacements = if ($config.name_replacements) { $config.name_replacements } else { @{} }
        $useRegex = if ($config.use_regex) { $config.use_regex } else { $false }

        # ========================================
        # STEP 1: RENAME DIRECTORIES
        # ========================================
        if ($directoryPatterns.Count -gt 0 -and $nameReplacements.Count -gt 0) {
            Write-Output "INFO: Processing directory renames..."

            # Find all matching directories
            $matchingDirs = @()
            foreach ($pattern in $directoryPatterns) {
                try {
                    # Get all directories recursively
                    $dirs = Get-ChildItem -Path $SourceDirectory -Directory -Recurse -ErrorAction SilentlyContinue

                    # Filter by pattern
                    $dirs = $dirs | Where-Object {
                        $relativePath = $_.FullName.Replace($SourceDirectory, '').TrimStart('\', '/')

                        # Simple wildcard matching
                        if ($pattern -match '\*\*/') {
                            $dirNamePattern = ($pattern -split '/')[-1]
                            $_.Name -like $dirNamePattern
                        }
                        else {
                            $relativePath -like $pattern.Replace('/', '\')
                        }
                    }

                    $matchingDirs += $dirs
                }
                catch {
                    Write-Warning "Could not search for directory pattern '$pattern': $($_.Exception.Message)"
                }
            }

            $matchingDirs = $matchingDirs | Select-Object -Unique
            Write-Output "INFO:   Found $($matchingDirs.Count) directories matching patterns"

            # Sort directories by depth (deepest first) to avoid parent-child conflicts
            $matchingDirs = $matchingDirs | Sort-Object { ($_.FullName -split '\\').Count } -Descending

            # Rename directories
            foreach ($dir in $matchingDirs) {
                $originalName = $dir.Name
                $newName = $originalName
                $replaced = $false

                # Apply name replacements
                foreach ($searchPattern in $nameReplacements.Keys) {
                    $replaceValue = $nameReplacements[$searchPattern]

                    if ($useRegex) {
                        if ($newName -match $searchPattern) {
                            $newName = $newName -replace $searchPattern, $replaceValue
                            $replaced = $true
                        }
                    }
                    else {
                        if ($newName.Contains($searchPattern)) {
                            $newName = $newName.Replace($searchPattern, $replaceValue)
                            $replaced = $true
                        }
                    }
                }

                # Perform rename if name changed
                if ($replaced -and $newName -ne $originalName) {
                    try {
                        $newPath = Join-Path $dir.Parent.FullName $newName

                        # Check if target already exists
                        if (Test-Path $newPath) {
                            Write-Warning "Cannot rename directory '$originalName' to '$newName' - target already exists"
                            continue
                        }

                        Rename-Item -Path $dir.FullName -NewName $newName -Force
                        Write-Output "INFO:   Renamed directory: $originalName -> $newName"
                        $directoriesRenamed++
                        $totalNameReplacements++
                    }
                    catch {
                        Write-Warning "Failed to rename directory '$originalName' to '$newName': $($_.Exception.Message)"
                    }
                }
            }
        }

        # ========================================
        # STEP 2: PROCESS FILE CONTENT & NAMES
        # ========================================
        if ($filePatterns.Count -gt 0) {
            Write-Output "INFO: Processing files..."

            # Find all matching files
            $matchingFiles = @()
            foreach ($pattern in $filePatterns) {
                try {
                    $files = Get-ChildItem -Path $SourceDirectory -File -Recurse -ErrorAction SilentlyContinue

                    # Apply pattern filtering
                    if ($pattern -match '\*\*/') {
                        $fileNamePattern = ($pattern -split '/')[-1]
                        $files = $files | Where-Object { $_.Name -like $fileNamePattern }
                    }
                    else {
                        $files = $files | Where-Object {
                            $relativePath = $_.FullName.Replace($SourceDirectory, '').TrimStart('\', '/')
                            $relativePath -like $pattern.Replace('/', '\')
                        }
                    }

                    $matchingFiles += $files
                }
                catch {
                    Write-Warning "Could not search for pattern '$pattern': $($_.Exception.Message)"
                }
            }

            $matchingFiles = $matchingFiles | Select-Object -Unique
            Write-Output "INFO:   Found $($matchingFiles.Count) files matching patterns"

            # Process each file
            foreach ($file in $matchingFiles) {
                try {
                    $relativePath = $file.FullName.Replace($SourceDirectory, '').TrimStart('\', '/')
                    Write-Output "INFO:   Processing file: $relativePath"

                    $contentChanged = $false
                    $nameChanged = $false

                    # CONTENT REPLACEMENT
                    if ($contentReplacements.Count -gt 0) {
                        # Backup original if requested
                        if ($BackupOriginals) {
                            $backupPath = "$($file.FullName).original"
                            Copy-Item -Path $file.FullName -Destination $backupPath -Force
                        }

                        # Read file content
                        $content = Get-Content -Path $file.FullName -Raw -Encoding $Encoding
                        $originalContent = $content
                        $fileContentReplacements = 0

                        # Apply content replacements
                        foreach ($searchPattern in $contentReplacements.Keys) {
                            $replaceValue = $contentReplacements[$searchPattern]

                            if ($useRegex) {
                                $matchCount = [regex]::Matches($content, $searchPattern)
                                if ($matchCount.Count -gt 0) {
                                    $content = $content -replace $searchPattern, $replaceValue
                                    $fileContentReplacements += $matchCount.Count
                                }
                            }
                            else {
                                $occurrences = ([regex]::Matches($content, [regex]::Escape($searchPattern))).Count
                                if ($occurrences -gt 0) {
                                    $content = $content.Replace($searchPattern, $replaceValue)
                                    $fileContentReplacements += $occurrences
                                }
                            }
                        }

                        # Write back if content changed
                        if ($content -ne $originalContent) {
                            Set-Content -Path $file.FullName -Value $content -Encoding $Encoding -NoNewline
                            Write-Output "INFO:     Content: $fileContentReplacements replacements applied"
                            $totalContentReplacements += $fileContentReplacements
                            $contentChanged = $true
                        }
                    }

                    # FILE NAME REPLACEMENT
                    if ($nameReplacements.Count -gt 0) {
                        $originalFileName = $file.Name
                        $newFileName = $originalFileName

                        # Apply name replacements
                        foreach ($searchPattern in $nameReplacements.Keys) {
                            $replaceValue = $nameReplacements[$searchPattern]

                            if ($useRegex) {
                                if ($newFileName -match $searchPattern) {
                                    $newFileName = $newFileName -replace $searchPattern, $replaceValue
                                }
                            }
                            else {
                                if ($newFileName.Contains($searchPattern)) {
                                    $newFileName = $newFileName.Replace($searchPattern, $replaceValue)
                                }
                            }
                        }

                        # Rename file if name changed
                        if ($newFileName -ne $originalFileName) {
                            try {
                                $newPath = Join-Path $file.DirectoryName $newFileName

                                if (Test-Path $newPath) {
                                    Write-Warning "Cannot rename file '$originalFileName' to '$newFileName' - target exists"
                                }
                                else {
                                    Rename-Item -Path $file.FullName -NewName $newFileName -Force
                                    Write-Output "INFO:     Filename: $originalFileName -> $newFileName"
                                    $totalNameReplacements++
                                    $nameChanged = $true
                                }
                            }
                            catch {
                                Write-Warning "Failed to rename file '$originalFileName': $($_.Exception.Message)"
                            }
                        }
                    }

                    if ($contentChanged -or $nameChanged) {
                        $filesProcessed++
                    }

                }
                catch {
                    Write-Warning "Failed to process file '$($file.FullName)': $($_.Exception.Message)"
                }
            }
        }
    }

    Write-Output "INFO: Template replacement completed"
    Write-Output "INFO:   Files processed: $filesProcessed"
    Write-Output "INFO:   Directories renamed: $directoriesRenamed"
    Write-Output "INFO:   Content replacements: $totalContentReplacements"
    Write-Output "INFO:   Name replacements: $totalNameReplacements"

    return @{
        FilesProcessed      = $filesProcessed
        DirectoriesRenamed  = $directoriesRenamed
        ContentReplacements = $totalContentReplacements
        NameReplacements    = $totalNameReplacements
    }
}

try {
    Write-Output "INFO: Starting repository synchronization..."
    Write-Output "INFO:   Source: Local submodule at $LocalSubmodulePath"
    Write-Output "INFO:   Target: $AdoOrg/$AdoProject/$AdoRepo"

    # === AZURE DEVOPS CONFIGURATION ===
    Write-Output "INFO: Configuring Azure DevOps CLI defaults..."
    az devops configure --defaults organization="https://dev.azure.com/$AdoOrg" project="$AdoProject"

    if ($LASTEXITCODE -ne 0) {
        throw "Error: Failed to configure Azure DevOps CLI defaults"
    }

    # === AUTHENTICATION SETUP ===
    Write-Output "INFO: Setting up authentication for Azure DevOps..."

    # Check if running in Azure DevOps pipeline with service principal
    $isAzureDevOpsPipeline = $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI -and $env:SYSTEM_ACCESSTOKEN
    $hasServicePrincipal = $env:servicePrincipalId -and $env:servicePrincipalKey
    $hasAzureDevOpsPat = $env:AZDO_PERSONAL_ACCESS_TOKEN

    if ($isAzureDevOpsPipeline) {
        Write-Output "INFO: Detected Azure DevOps pipeline environment"

        if ($env:SYSTEM_ACCESSTOKEN) {
            Write-Output "INFO: Using System.AccessToken for authentication"
            # Set up git credential helper for Azure DevOps using the pipeline token
            git config --global credential."https://dev.azure.com".helper ""
            git config --global credential."https://dev.azure.com".helper "!f() { echo username=PAT; echo password=$env:SYSTEM_ACCESSTOKEN; }; f"
        }
        else {
            throw "Error: System.AccessToken not available in pipeline"
        }
    }
    elseif ($hasServicePrincipal) {
        Write-Output "INFO: Using service principal authentication"

        # For service principal, we need to get an access token and use it with git
        try {
            # Get access token using service principal
            $tokenResponse = az account get-access-token --resource "499b84ac-1321-427f-aa17-267ca6975798" --query "accessToken" -o tsv

            if ($LASTEXITCODE -ne 0 -or -not $tokenResponse) {
                throw "Failed to get access token with service principal"
            }

            Write-Output "INFO: Successfully obtained access token with service principal"

            # Configure git to use the access token
            git config --global credential."https://dev.azure.com".helper ""
            git config --global credential."https://dev.azure.com".helper "!f() { echo username=PAT; echo password=$tokenResponse; }; f"
        }
        catch {
            Write-Warning "INFO: Service principal token method failed, trying PAT fallback..."

            if ($hasAzureDevOpsPat) {
                Write-Output "INFO: Using AZDO_PERSONAL_ACCESS_TOKEN for authentication"
                git config --global credential."https://dev.azure.com".helper ""
                git config --global credential."https://dev.azure.com".helper "!f() { echo username=PAT; echo password=$env:AZDO_PERSONAL_ACCESS_TOKEN; }; f"
            }
            else {
                throw "Error: No valid authentication method available"
            }
        }
    }
    elseif ($hasAzureDevOpsPat) {
        Write-Output "INFO: Using AZDO_PERSONAL_ACCESS_TOKEN for authentication"
        git config --global credential."https://dev.azure.com".helper ""
        git config --global credential."https://dev.azure.com".helper "!f() { echo username=PAT; echo password=$env:AZDO_PERSONAL_ACCESS_TOKEN; }; f"
    }
    else {
        Write-Output "INFO: Using existing Azure CLI authentication context"

        # Try to get access token from Azure CLI session
        try {
            $cliToken = az account get-access-token --resource "499b84ac-1321-427f-aa17-267ca6975798" --query "accessToken" -o tsv 2>$null

            if ($LASTEXITCODE -eq 0 -and $cliToken) {
                Write-Output "INFO: Using Azure CLI session token for git authentication"
                git config --global credential."https://dev.azure.com".helper ""
                git config --global credential."https://dev.azure.com".helper "!f() { echo username=PAT; echo password=$cliToken; }; f"
            }
            else {
                throw "No valid Azure CLI session found"
            }
        }
        catch {
            Write-Warning "INFO: Could not use Azure CLI authentication. Please ensure 'az login' was run or use AZDO_PERSONAL_ACCESS_TOKEN"
            Write-Warning "INFO: Proceeding without explicit git credential configuration - git may prompt for credentials"
        }
    }

    # Validate authentication
    Write-Output "INFO: Validating authentication..."
    az devops project show --organization "https://dev.azure.com/$AdoOrg" --project $AdoProject --output none

    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Azure DevOps authentication failed. Please ensure:"
        Write-Error "ERROR:   1. You've run 'az login' or have valid service principal credentials"
        Write-Error "ERROR:   2. AZDO_PERSONAL_ACCESS_TOKEN is set (if using PAT)"
        Write-Error "ERROR:   3. System.AccessToken is available (if in Azure DevOps pipeline)"
        Write-Error "ERROR:   4. You have access to organization '$AdoOrg' and project '$AdoProject'"
        exit 1
    }

    # Create temporary directory
    $tempDir = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_ }
    Write-Output "INFO: Created temp directory: $tempDir"

    try {
        # Validate and prepare local submodule
        Write-Output "INFO: Validating local submodule..."

        # Resolve absolute path to submodule
        $submoduleAbsPath = Resolve-Path -Path $LocalSubmodulePath -ErrorAction SilentlyContinue
        if (-not $submoduleAbsPath -or -not (Test-Path $submoduleAbsPath)) {
            throw "Error: Local submodule not found at path: $LocalSubmodulePath"
        }

        Write-Output "INFO: Found submodule at: $submoduleAbsPath"

        # Check if it's a git repository
        if (-not (Test-Path (Join-Path $submoduleAbsPath ".git"))) {
            throw "Error: Local path is not a git repository: $submoduleAbsPath"
        }

        # Get current commit hash from submodule
        Set-Location $submoduleAbsPath
        $submoduleCommit = git rev-parse HEAD
        $submoduleMessage = git log -1 --pretty=format:"%s"
        $submoduleBranch = git branch --show-current

        if ($LASTEXITCODE -ne 0) {
            throw "Error: Failed to get commit information from submodule"
        }

        Write-Output "INFO: Submodule current commit: $submoduleCommit"
        Write-Output "INFO: Submodule current branch: $submoduleBranch"
        Write-Output "INFO: Latest commit message: $submoduleMessage"

        # Copy submodule to temp directory for processing
        Set-Location $tempDir
        Write-Output "INFO: Copying submodule contents to temp directory..."

        # Create source directory first
        New-Item -ItemType Directory -Path "./source" -Force | Out-Null

        # Determine what to copy based on IncludeSubfolders parameter
        if ($IncludeSubfolders -and $IncludeSubfolders.Count -gt 0) {
            Write-Output "INFO: Selective sync enabled - including only specified subfolders:"
            foreach ($subfolder in $IncludeSubfolders) {
                Write-Output "INFO:   - $subfolder"
            }

            # Copy only specified subfolders, respecting .gitignore
            Set-Location $submoduleAbsPath

            foreach ($subfolder in $IncludeSubfolders) {
                $sourcePath = Join-Path $submoduleAbsPath $subfolder

                if (Test-Path $sourcePath) {
                    $destinationPath = Join-Path "$tempDir/source" $subfolder

                    # Ensure parent directory exists
                    $parentDir = Split-Path $destinationPath -Parent
                    if ($parentDir -and -not (Test-Path $parentDir)) {
                        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
                    }

                    if (Test-Path $sourcePath -PathType Container) {
                        Write-Output "INFO:   Copying directory (respecting .gitignore): $subfolder"

                        # Use git archive to respect .gitignore
                        $archiveFile = Join-Path $tempDir "archive-$([guid]::NewGuid().ToString()).tar"
                        git archive --format=tar --output="$archiveFile" HEAD "$subfolder" 2>$null

                        if ($LASTEXITCODE -eq 0 -and (Test-Path $archiveFile)) {
                            # Extract archive to temp location
                            $extractDir = Join-Path $tempDir "extract-$([guid]::NewGuid().ToString())"
                            New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
                            tar -xf "$archiveFile" -C "$extractDir"

                            # Copy extracted contents to destination
                            $extractedSource = Join-Path $extractDir $subfolder
                            if (Test-Path $extractedSource) {
                                Copy-Item -Path $extractedSource -Destination $destinationPath -Recurse -Force
                            }

                            # Cleanup
                            Remove-Item $archiveFile -Force -ErrorAction SilentlyContinue
                            Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
                        }
                        else {
                            # Fallback to regular copy if git archive fails
                            Write-Warning "git archive failed for $subfolder, using regular copy"
                            Copy-Item -Path $sourcePath -Destination $destinationPath -Recurse -Force
                        }
                    }
                    else {
                        Write-Output "INFO:   Copying file: $subfolder"
                        Copy-Item -Path $sourcePath -Destination $destinationPath -Force
                    }
                }
                else {
                    Write-Warning "Specified subfolder/file not found in source: $subfolder"
                }
            }

            Set-Location $tempDir
        }
        else {
            Write-Output "INFO: Full repository sync - copying all contents"

            # Copy all contents including subdirectories, preserving structure
            Get-ChildItem -Path $submoduleAbsPath -Force | Where-Object { $_.Name -ne '.git' } | ForEach-Object {
                $destinationPath = Join-Path "./source" $_.Name
                if ($_.PSIsContainer) {
                    Write-Output "INFO:   Copying directory: $($_.Name)"
                    Copy-Item -Path $_.FullName -Destination $destinationPath -Recurse -Force
                }
                else {
                    Write-Output "INFO:   Copying file: $($_.Name)"
                    Copy-Item -Path $_.FullName -Destination $destinationPath -Force
                }
            }
        }

        # Verify directory structure was preserved
        Write-Output "INFO: Copied directory structure:"
        Get-ChildItem -Path "./source" -Recurse -Directory | ForEach-Object {
            $relativePath = $_.FullName.Replace((Resolve-Path "./source").Path, "").TrimStart('\', '/')
            Write-Output "INFO:   Directory: $relativePath"
        }

        # Create a minimal source info for commit tracking
        Set-Content -Path "./source/.sync-info" -Value @"
# Sync Information
Commit: $submoduleCommit
Branch: $submoduleBranch
Message: $submoduleMessage
SyncTime: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')
"@

        # Clone Azure DevOps repository with authentication
        Write-Output "INFO: Cloning Azure DevOps repository..."
        $adoRepoUrl = "https://dev.azure.com/$AdoOrg/$([uri]::EscapeDataString($AdoProject))/_git/$([uri]::EscapeDataString($AdoRepo))"

        # Clone with explicit credential handling
        git -c core.askpass=true clone $adoRepoUrl target

        if ($LASTEXITCODE -ne 0) {
            throw "Error: Failed to clone Azure DevOps repository. Check authentication and repository access."
        }

        # Copy files from submodule to Azure DevOps repo (excluding .git)
        Write-Output "INFO: Syncing files..."
        Set-Location target

        # Selective sync mode: only remove and update specified folders
        if ($IncludeSubfolders -and $IncludeSubfolders.Count -gt 0) {
            Write-Output "INFO: Selective sync mode - updating only specified paths"

            foreach ($subfolder in $IncludeSubfolders) {
                $sourcePath = Join-Path "../source" $subfolder
                $targetPath = $subfolder

                if (Test-Path $sourcePath) {
                    # Remove existing target path if it exists
                    if (Test-Path $targetPath) {
                        Write-Output "INFO:   Removing existing: $targetPath"
                        Remove-Item -Path $targetPath -Recurse -Force
                    }

                    # Ensure parent directory exists
                    $parentDir = Split-Path $targetPath -Parent
                    if ($parentDir -and -not (Test-Path $parentDir)) {
                        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
                    }

                    # Copy new content
                    Write-Output "INFO:   Copying new content: $targetPath"
                    if (Test-Path $sourcePath -PathType Container) {
                        Copy-Item -Path $sourcePath -Destination $targetPath -Recurse -Force
                    }
                    else {
                        Copy-Item -Path $sourcePath -Destination $targetPath -Force
                    }
                }
            }

            Write-Output "INFO: Selective sync complete - other files/folders in repo preserved"
        }
        else {
            Write-Output "INFO: Full repository sync - replacing all contents"

            # Remove existing files (except .git)
            Get-ChildItem -Force | Where-Object { $_.Name -ne '.git' } | Remove-Item -Recurse -Force

            # Copy new files
            Copy-Item -Path "../source/*" -Destination "." -Recurse -Force -Exclude ".git"
        }

        # ========================================
        # APPLY TEMPLATE REPLACEMENTS (after copying to temp folder)
        # ========================================
        if ($TemplateReplacements -and $TemplateReplacements.Count -gt 0) {
            Write-Output "INFO: Applying template replacements..."
            $replacementResult = Invoke-TemplateReplacement -SourceDirectory "." -ReplacementConfigs $TemplateReplacements
            Write-Output "INFO: Template processing complete - $($replacementResult.FilesProcessed) files and $($replacementResult.DirectoriesRenamed) directories modified"
        }

        # Configure git user (use Azure DevOps service user)
        git config user.email "azure-devops@noreply.microsoft.com"
        git config user.name "Azure DevOps Sync"

        # Check if there are changes
        git add -A
        $changes = git status --porcelain

        if ($changes -or $ForceSync) {
            Write-Output "INFO: Changes detected or force sync enabled. Committing and pushing..."

            # Get sync info from the copied source
            $syncInfo = Get-Content "../source/.sync-info" -Raw -ErrorAction SilentlyContinue

            # Commit changes with submodule information
            $commitMessage = "ECP config: git repo sync: $(Get-Date -Format 'yy-MM-dd HH:mm UTC')`n`nSubmodule commit: $submoduleCommit`nMessage: $submoduleMessage`nBranch: $submoduleBranch`n`nSync Details:`n$syncInfo"
            git commit -m "$commitMessage"

            if ($LASTEXITCODE -ne 0) {
                throw "Error: Failed to commit changes"
            }

            # Push to Azure DevOps
            git push origin $TargetBranch

            if ($LASTEXITCODE -ne 0) {
                throw "Error: Failed to push to Azure DevOps repository"
            }

            Write-Output "INFO: Successfully synchronized repository"
        }
        else {
            Write-Output "INFO: No changes detected, skipping commit"
        }

    }
    finally {
        # Cleanup git configuration
        git config --global --unset credential."https://dev.azure.com".helper 2>$null

        # Cleanup temporary directory
        Set-Location $env:TEMP
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Output "INFO: Cleaned up temporary directory"
    }

}
catch {
    Write-Error "Synchronization failed: $($_.Exception.Message)"
    exit 1
}
