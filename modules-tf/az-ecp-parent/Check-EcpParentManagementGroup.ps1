#!/usr/bin/env pwsh
# External data source script for Terraform
# Reads JSON from stdin, outputs JSON to stdout

$ErrorActionPreference = 'Stop'

# Read input from Terraform
$jsonInput = [Console]::In.ReadToEnd() | ConvertFrom-Json
$parent_management_group_id = $jsonInput.parent_management_group_id
$parent_management_group_display_name = $jsonInput.parent_management_group_display_name
$tenant_id = $jsonInput.tenant_id

function Wait-TenantBackfill {
    param(
        [int]$MaxWaitMinutes = 10,
        [int]$PollIntervalSeconds = 10
    )
    
    $startTime = Get-Date
    
    while (((Get-Date) - $startTime).TotalMinutes -lt $MaxWaitMinutes) {
        Start-Sleep -Seconds $PollIntervalSeconds
        
        $bfStatus = az rest --method POST --url "https://management.azure.com/providers/Microsoft.Management/tenantBackfillStatus?api-version=2020-05-01"
        $status = ($bfStatus | ConvertFrom-Json).status
        
        if ($status -ieq "Completed") {
            return @{ Success = $true; Status = $bfStatus }
        }
        elseif ($status -ine "Started") {
            return @{ Success = $false; Status = $bfStatus }
        }
        
        $elapsed = [int]((Get-Date) - $startTime).TotalMinutes
    }
    return @{ Success = $false; Status = $null }
}

# check if root management group already exists (backfill had happened in the past)
$bfStatus = az rest --method POST --url "https://management.azure.com/providers/Microsoft.Management/tenantBackfillStatus?api-version=2020-05-01"
if ($bfStatus -and ($bfStatus | ConvertFrom-Json).status -ieq "Completed") {
    $tenantRootMgId = "/providers/Microsoft.Management/managementGroups/$tenant_id"
    $tenantRootBackfillStatus = "Completed"
}
elseif ($bfStatus -and ($bfStatus | ConvertFrom-Json).status -ieq "Started") {
    $result = Wait-TenantBackfill -MaxWaitMinutes 10 -PollIntervalSeconds 15
    if ($result.Success) {
        $tenantRootMgId = "/providers/Microsoft.Management/managementGroups/$tenant_id"
        $tenantRootBackfillStatus = "Started"
    }
    else {
        Write-Error "Tenant backfill failed or timed out"
        exit 1
    }
}
else {
    Write-Host "INFO: Root Management Group does not exist yet - starting TenantBackfill for this tenant." -ForegroundColor Yellow
    az rest --method POST --url "https://management.azure.com/providers/Microsoft.Management/startTenantBackfill?api-version=2020-05-01" | Out-Null
    $result = Wait-TenantBackfill -MaxWaitMinutes 10 -PollIntervalSeconds 15
    if ($result.Success) {
        $tenantRootMgId = "/providers/Microsoft.Management/managementGroups/$tenant_id"
        $tenantRootBackfillStatus = "Completed (this run)"
    }
    else {
        Write-Error "Tenant backfill failed or timed out"
        exit 1
    }
}

# Check if parent management group already exists
$existingMg = az rest --method GET --url "https://management.azure.com/providers/Microsoft.Management/managementGroups/$($parent_management_group_id)?api-version=2020-05-01" 2>$null | ConvertFrom-Json
if ($existingMg) {
    $parentMgName = $parent_management_group_id
    $parentMgDisplayName = $($existingMg.properties.displayName)
    $parentMgId = $($existingMg.id)
    $parentMgStatus = "Existing"
    $parentAction = "None"
}
else {
    $mgBody = @{
        properties = @{
            displayName = "$parent_management_group_display_name"
            details     = @{
                parent = @{
                    id = "/providers/Microsoft.Management/managementGroups/$tenant_id"
                }
            }
        }
    }
    
    # Write body to temp file to avoid PowerShell string escaping issues
    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        $mgBody | ConvertTo-Json -Depth 10 -Compress | Out-File -FilePath $tempFile -Encoding utf8 -NoNewline
        
        $createResult = az rest --method PUT --url "https://management.azure.com/providers/Microsoft.Management/managementGroups/$($parent_management_group_id)?api-version=2020-05-01" --body "@$tempFile" 2>&1
        
        if ($LASTEXITCODE -ieq 0) {
            $parentMgName = $parent_management_group_id
            $parentMgDisplayName = $parent_management_group_display_name
            $parentMgId = "/providers/Microsoft.Management/managementGroups/$parent_management_group_id"
            $parentMgStatus = "Existing"
            $parentAction = "Created"
        }
        else {
            Write-Error "Failed to create parent management group: $createResult"
            exit 1
        }
    }
    finally {
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

# output for external data source (must be valid JSON to stdout)
@{
    tenant_root_management_group_id      = $tenantRootMgId
    tenant_root_backfill_status          = $tenantRootBackfillStatus
    parent_management_group_name         = $parentMgName
    parent_management_group_display_name = $parentMgDisplayName
    parent_management_group_id           = $parentMgId
    parent_management_group_status       = $parentMgStatus
    parent_management_group_action       = $parentAction
} | ConvertTo-Json -Compress
