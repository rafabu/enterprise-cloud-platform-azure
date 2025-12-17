#!/usr/bin/env pwsh
# Read JSON from stdin (Terraform external data source protocol)
$jsonInput = [Console]::In.ReadToEnd() | ConvertFrom-Json

# Decode the base64-encoded UTF-16LE string
$renderedFilesJson = [System.Text.Encoding]::Unicode.GetString(
    [System.Convert]::FromBase64String($jsonInput.rendered_files_base64)
)
$renderedFiles = $renderedFilesJson | ConvertFrom-Json

# Get unique destination folders
$destinationFolders = $renderedFiles.PSObject.Properties.Value.destination_file_path | 
    ForEach-Object { Split-Path -Parent $_ } | 
    Select-Object -Unique

# Delete and recreate destination folders
foreach ($folder in $destinationFolders) {
    if (Test-Path $folder) {
        Write-Verbose "Removing existing folder: $folder"
        Remove-Item -Path $folder -Recurse -Force
    }
    
    Write-Verbose "Creating folder: $folder"
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
}

# Write rendered files
$filesWritten = 0
foreach ($fileEntry in $renderedFiles.PSObject.Properties) {
    $fileInfo = $fileEntry.Value
    $destinationPath = $fileInfo.destination_file_path
    $content = $fileInfo.rendered_file_content
    
    # Ensure parent directory exists
    $parentDir = Split-Path -Parent $destinationPath
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }
    
    # Write file content
    Write-Verbose "Writing file: $destinationPath"
    $content | Out-File -FilePath $destinationPath -Encoding utf8 -NoNewline
    $filesWritten++
}

# short delay to ensure all file handles are released
Start-Sleep -Seconds 10 | Out-Null

# Return result to Terraform (external data source protocol requires JSON output)
@{
    files_written = $filesWritten.ToString()
    status        = "success"
} | ConvertTo-Json
