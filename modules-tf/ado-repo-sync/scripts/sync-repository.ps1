#!/usr/bin/env pwsh
param(
    [string]$LocalSubmodulePath,
    [string]$AdoOrg,
    [string]$AdoProject,
    [string]$AdoRepo,
    [string]$TargetBranch,
    [bool]$ForceSync = $false
)

# Set error handling
$ErrorActionPreference = 'Stop'

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
    Write-Host "INFO: Validating authentication..."
    
    az devops project show --organization "https://dev.azure.com/$AdoOrg" --project $AdoProject --output none
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Azure DevOps authentication failed. Please ensure:"
        Write-Error "ERROR:   1. You've run 'az login' or set AZURE_DEVOPS_EXT_PAT"
        Write-Error "ERROR:   2. You have access to organization '$AdoOrg' and project '$AdoProject'"
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
            } else {
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
        
        # Clone Azure DevOps repository
        Write-Host "INFO: Cloning Azure DevOps repository..."
        $adoRepoUrl = "https://dev.azure.com/$AdoOrg/$AdoProject/_git/$AdoRepo"
        git clone $adoRepoUrl target
        
        if ($LASTEXITCODE -ne 0) {
            throw "Error: Failed to clone Azure DevOps repository"
        }
        
        # Copy files from GitHub to Azure DevOps repo (excluding .git)
        Write-Host "INFO: Syncing files..."
        Set-Location target
        
        # Remove existing files (except .git)
        Get-ChildItem -Force | Where-Object { $_.Name -ne '.git' } | Remove-Item -Recurse -Force
        
        # Copy new files
        Copy-Item -Path "../source/*" -Destination "." -Recurse -Force -Exclude ".git"
        
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
            $commitMessage = "Sync from local submodule`n`nSubmodule commit: $submoduleCommit`nMessage: $submoduleMessage`nBranch: $submoduleBranch`n`nSync Details:`n$syncInfo"
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
        } else {
            Write-Host "INFO: No changes detected, skipping commit"
        }
        
    } finally {
        # Cleanup
        Set-Location $env:TEMP
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "INFO: Cleaned up temporary directory"
    }
    
} catch {
    Write-Error "Synchronization failed: $($_.Exception.Message)"
    exit 1
}