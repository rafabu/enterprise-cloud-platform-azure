#!/usr/bin/env pwsh
param(
    [string]$LocalSubmodulePath,
    [string]$AdoOrg,
    [string]$AdoProject,
    [string]$AdoRepo,
    [string]$TargetBranch,
    [object]$TemplateReplacements = @{},
    [bool]$ForceSync = $false
)

# Set error handling
$ErrorActionPreference = 'Stop'

#!/usr/bin/env pwsh
function Apply-TemplateReplacements {
    param(
        [string]$SourceDirectory,
        [object]$ReplacementConfigs,
        [string]$Encoding = "utf8",
        [bool]$BackupOriginals = $false
    )
    
    Write-Host "INFO: Starting template replacement processing..."
    
    if (-not $ReplacementConfigs -or $ReplacementConfigs.Count -eq 0) {
        Write-Host "INFO: No template replacements configured, skipping"
        return
    }
    
    $totalContentReplacements = 0
    $totalNameReplacements = 0
    $filesProcessed = 0
    $directoriesRenamed = 0
    
    foreach ($configKey in $ReplacementConfigs.Keys) {
        $config = $ReplacementConfigs[$configKey]
        Write-Host "INFO: Processing replacement group: $configKey"
        
        $filePatterns = if ($config.file_patterns) { $config.file_patterns } else { @() }
        $directoryPatterns = if ($config.directory_patterns) { $config.directory_patterns } else { @() }
        $contentReplacements = if ($config.content_replacements) { $config.content_replacements } else { @{} }
        $nameReplacements = if ($config.name_replacements) { $config.name_replacements } else { @{} }
        $useRegex = if ($config.use_regex) { $config.use_regex } else { $false }
        
        # ========================================
        # STEP 1: RENAME DIRECTORIES
        # ========================================
        if ($directoryPatterns.Count -gt 0 -and $nameReplacements.Count -gt 0) {
            Write-Host "INFO: Processing directory renames..."
            
            # Find all matching directories
            $matchingDirs = @()
            foreach ($pattern in $directoryPatterns) {
                $psPattern = $pattern -replace '\*\*/', '*' -replace '/', '\'
                
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
            Write-Host "INFO:   Found $($matchingDirs.Count) directories matching patterns"
            
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
                        Write-Host "INFO:   Renamed directory: $originalName → $newName"
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
            Write-Host "INFO: Processing files..."
            
            # Find all matching files
            $matchingFiles = @()
            foreach ($pattern in $filePatterns) {
                $psPattern = $pattern -replace '\*\*/', '*' -replace '/', '\'
                
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
            Write-Host "INFO:   Found $($matchingFiles.Count) files matching patterns"
            
            # Process each file
            foreach ($file in $matchingFiles) {
                try {
                    $relativePath = $file.FullName.Replace($SourceDirectory, '').TrimStart('\', '/')
                    Write-Host "INFO:   Processing file: $relativePath"
                    
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
                                $matches = [regex]::Matches($content, $searchPattern)
                                if ($matches.Count -gt 0) {
                                    $content = $content -replace $searchPattern, $replaceValue
                                    $fileContentReplacements += $matches.Count
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
                            Write-Host "INFO:     Content: $fileContentReplacements replacements applied"
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
                                    Write-Host "INFO:     Filename: $originalFileName → $newFileName"
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
    
    Write-Host "INFO: Template replacement completed"
    Write-Host "INFO:   Files processed: $filesProcessed"
    Write-Host "INFO:   Directories renamed: $directoriesRenamed"
    Write-Host "INFO:   Content replacements: $totalContentReplacements"
    Write-Host "INFO:   Name replacements: $totalNameReplacements"
    
    return @{
        FilesProcessed      = $filesProcessed
        DirectoriesRenamed  = $directoriesRenamed
        ContentReplacements = $totalContentReplacements
        NameReplacements    = $totalNameReplacements
    }
}

try {
    Write-Host "INFO: Starting repository synchronization..."
    Write-Host "INFO:   Source: Local submodule at $LocalSubmodulePath"
    Write-Host "INFO:   Target: $AdoOrg/$AdoProject/$AdoRepo"

    # === AZURE DEVOPS CONFIGURATION ===
    Write-Host "INFO: Configuring Azure DevOps CLI defaults..."
    az devops configure --defaults organization="https://dev.azure.com/$AdoOrg" project="$AdoProject"
    
    if ($LASTEXITCODE -ne 0) {
        throw "Error: Failed to configure Azure DevOps CLI defaults"
    }
    
    # === AUTHENTICATION SETUP ===
    Write-Host "INFO: Setting up authentication for Azure DevOps..."
    
    # Check if running in Azure DevOps pipeline with service principal
    $isAzureDevOpsPipeline = $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI -and $env:SYSTEM_ACCESSTOKEN
    $hasServicePrincipal = $env:servicePrincipalId -and $env:servicePrincipalKey
    $hasAzureDevOpsPat = $env:AZURE_DEVOPS_EXT_PAT
    
    if ($isAzureDevOpsPipeline) {
        Write-Host "INFO: Detected Azure DevOps pipeline environment"
        
        if ($env:SYSTEM_ACCESSTOKEN) {
            Write-Host "INFO: Using System.AccessToken for authentication"
            # Set up git credential helper for Azure DevOps using the pipeline token
            git config --global credential."https://dev.azure.com".helper ""
            git config --global credential."https://dev.azure.com".helper "!f() { echo username=PAT; echo password=$env:SYSTEM_ACCESSTOKEN; }; f"
        }
        else {
            throw "Error: System.AccessToken not available in pipeline"
        }
    }
    elseif ($hasServicePrincipal) {
        Write-Host "INFO: Using service principal authentication"
        
        # For service principal, we need to get an access token and use it with git
        try {
            # Get access token using service principal
            $tokenResponse = az account get-access-token --resource "499b84ac-1321-427f-aa17-267ca6975798" --query "accessToken" -o tsv
            
            if ($LASTEXITCODE -ne 0 -or -not $tokenResponse) {
                throw "Failed to get access token with service principal"
            }
            
            Write-Host "INFO: Successfully obtained access token with service principal"
            
            # Configure git to use the access token
            git config --global credential."https://dev.azure.com".helper ""
            git config --global credential."https://dev.azure.com".helper "!f() { echo username=PAT; echo password=$tokenResponse; }; f"
        }
        catch {
            Write-Warning "INFO: Service principal token method failed, trying PAT fallback..."
            
            if ($hasAzureDevOpsPat) {
                Write-Host "INFO: Using AZURE_DEVOPS_EXT_PAT for authentication"
                git config --global credential."https://dev.azure.com".helper ""
                git config --global credential."https://dev.azure.com".helper "!f() { echo username=PAT; echo password=$env:AZURE_DEVOPS_EXT_PAT; }; f"
            }
            else {
                throw "Error: No valid authentication method available"
            }
        }
    }
    elseif ($hasAzureDevOpsPat) {
        Write-Host "INFO: Using AZURE_DEVOPS_EXT_PAT for authentication"
        git config --global credential."https://dev.azure.com".helper ""
        git config --global credential."https://dev.azure.com".helper "!f() { echo username=PAT; echo password=$env:AZURE_DEVOPS_EXT_PAT; }; f"
    }
    else {
        Write-Host "INFO: Using existing Azure CLI authentication context"
    
        # Try to get access token from Azure CLI session
        try {
            $cliToken = az account get-access-token --resource "499b84ac-1321-427f-aa17-267ca6975798" --query "accessToken" -o tsv 2>$null
        
            if ($LASTEXITCODE -eq 0 -and $cliToken) {
                Write-Host "INFO: Using Azure CLI session token for git authentication"
                git config --global credential."https://dev.azure.com".helper ""
                git config --global credential."https://dev.azure.com".helper "!f() { echo username=PAT; echo password=$cliToken; }; f"
            }
            else {
                throw "No valid Azure CLI session found"
            }
        }
        catch {
            Write-Warning "INFO: Could not use Azure CLI authentication. Please ensure 'az login' was run or use AZURE_DEVOPS_EXT_PAT"
            Write-Warning "INFO: Proceeding without explicit git credential configuration - git may prompt for credentials"
        }
    }
    
    # Validate authentication
    Write-Host "INFO: Validating authentication..."
    az devops project show --organization "https://dev.azure.com/$AdoOrg" --project $AdoProject --output none
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Azure DevOps authentication failed. Please ensure:"
        Write-Error "ERROR:   1. You've run 'az login' or have valid service principal credentials"
        Write-Error "ERROR:   2. AZURE_DEVOPS_EXT_PAT is set (if using PAT)"
        Write-Error "ERROR:   3. System.AccessToken is available (if in Azure DevOps pipeline)"
        Write-Error "ERROR:   4. You have access to organization '$AdoOrg' and project '$AdoProject'"
        exit 1
    }
    
    # Create temporary directory
    $tempDir = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_ }
    Write-Host "INFO: Created temp directory: $tempDir"
    
    try {
        # Validate and prepare local submodule
        Write-Host "INFO: Validating local submodule..."
        
        # Resolve absolute path to submodule
        $submoduleAbsPath = Resolve-Path -Path $LocalSubmodulePath -ErrorAction SilentlyContinue
        if (-not $submoduleAbsPath -or -not (Test-Path $submoduleAbsPath)) {
            throw "Error: Local submodule not found at path: $LocalSubmodulePath"
        }
        
        Write-Host "INFO: Found submodule at: $submoduleAbsPath"
        
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
        
        Write-Host "INFO: Submodule current commit: $submoduleCommit"
        Write-Host "INFO: Submodule current branch: $submoduleBranch"
        Write-Host "INFO: Latest commit message: $submoduleMessage"
        
        # Copy submodule to temp directory for processing
        Set-Location $tempDir
        Write-Host "INFO: Copying submodule contents to temp directory..."
        
        # Create source directory first
        New-Item -ItemType Directory -Path "./source" -Force | Out-Null
        
        # Copy all contents including subdirectories, preserving structure
        Get-ChildItem -Path $submoduleAbsPath -Force | Where-Object { $_.Name -ne '.git' } | ForEach-Object {
            $destinationPath = Join-Path "./source" $_.Name
            if ($_.PSIsContainer) {
                Write-Host "INFO:   Copying directory: $($_.Name)"
                Copy-Item -Path $_.FullName -Destination $destinationPath -Recurse -Force
            }
            else {
                Write-Host "INFO:   Copying file: $($_.Name)"
                Copy-Item -Path $_.FullName -Destination $destinationPath -Force
            }
        }
        
        # Verify directory structure was preserved
        Write-Host "INFO: Copied directory structure:"
        Get-ChildItem -Path "./source" -Recurse -Directory | ForEach-Object {
            $relativePath = $_.FullName.Replace((Resolve-Path "./source").Path, "").TrimStart('\', '/')
            Write-Host "INFO:   Directory: $relativePath"
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
        Write-Host "INFO: Cloning Azure DevOps repository..."
        $adoRepoUrl = "https://dev.azure.com/$AdoOrg/$AdoProject/_git/$AdoRepo"
        
        # Clone with explicit credential handling
        git -c core.askpass=true clone $adoRepoUrl target
        
        if ($LASTEXITCODE -ne 0) {
            throw "Error: Failed to clone Azure DevOps repository. Check authentication and repository access."
        }
        
        # Copy files from submodule to Azure DevOps repo (excluding .git)
        Write-Host "INFO: Syncing files..."
        Set-Location target
        
        # Remove existing files (except .git)
        Get-ChildItem -Force | Where-Object { $_.Name -ne '.git' } | Remove-Item -Recurse -Force
        
        # Copy new files
        Copy-Item -Path "../source/*" -Destination "." -Recurse -Force -Exclude ".git"
        
        # ========================================
        # APPLY TEMPLATE REPLACEMENTS (after copying to temp folder)
        # ========================================
        if ($TemplateReplacements -and $TemplateReplacements.Count -gt 0) {
            Write-Host "INFO: Applying template replacements..."
            $replacementResult = Apply-TemplateReplacements -SourceDirectory "." -ReplacementConfigs $TemplateReplacements
            Write-Host "INFO: Template processing complete - $($replacementResult.FilesProcessed) files and $($replacementResult.DirectoriesRenamed) directories modified"
        }

        # Configure git user (use Azure DevOps service user)
        git config user.email "azure-devops@noreply.microsoft.com"
        git config user.name "Azure DevOps Sync"
        
        # Check if there are changes
        git add -A
        $changes = git status --porcelain
        
        if ($changes -or $ForceSync) {
            Write-Host "INFO: Changes detected or force sync enabled. Committing and pushing..."
            
            # Get sync info from the copied source
            $syncInfo = Get-Content "../source/.sync-info" -Raw -ErrorAction SilentlyContinue
            
            # Commit changes with submodule information
            $commitMessage = "ECP config: Automation submodule sync: $(Get-Date -Format 'yy-MM-dd HH:mm UTC')`n`nSubmodule commit: $submoduleCommit`nMessage: $submoduleMessage`nBranch: $submoduleBranch`n`nSync Details:`n$syncInfo"
            git commit -m "$commitMessage"
            
            if ($LASTEXITCODE -ne 0) {
                throw "Error: Failed to commit changes"
            }
            
            # Push to Azure DevOps
            git push origin $TargetBranch
            
            if ($LASTEXITCODE -ne 0) {
                throw "Error: Failed to push to Azure DevOps repository"
            }
            
            Write-Host "INFO: Successfully synchronized repository"
        }
        else {
            Write-Host "INFO: No changes detected, skipping commit"
        }
        
    }
    finally {
        # Cleanup git configuration
        git config --global --unset credential."https://dev.azure.com".helper 2>$null
        
        # Cleanup temporary directory
        Set-Location $env:TEMP
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "INFO: Cleaned up temporary directory"
    }
    
}
catch {
    Write-Error "Synchronization failed: $($_.Exception.Message)"
    exit 1
}
