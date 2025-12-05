# new Entra tenants will not have been enabled for using management groups
#     TenantBackfill is required. See
#     https://learn.microsoft.com/en-us/cli/azure/account/management-group/tenant-backfill?view=azure-cli-latest
data "external" "ecp_parent_mg_check" {
  program = ["pwsh", "-NoLogo", "-NonInteractive", "-ExecutionPolicy", "RemoteSigned", "-command", <<-SCRIPT
    
$parent_management_group_id = "${var.ecp_azure_root_parent_management_group_id}"
$parent_management_group_display_name = "ECP Root Management Group"
$tenant_id = "${data.azurerm_client_config.this.tenant_id}"

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
        exit 1
    }
}
else {
    Write-Output "INFO: Root Management Group does not exist yet - starting TenantBackfill for this tenant."
    az rest --method POST --url "https://management.azure.com/providers/Microsoft.Management/startTenantBackfill?api-version=2020-05-01"
    $result = Wait-TenantBackfill -MaxWaitMinutes 10 -PollIntervalSeconds 15
    if ($result.Success) {
        $tenantRootMgId = "/providers/Microsoft.Management/managementGroups/$tenant_id"
        $tenantRootBackfillStatus = "Completed (this run)"
    }
    else {
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
    $mgBodyJson = ($mgBody | ConvertTo-Json -Depth 10 -Compress).Replace('"', '\"')
    $createResult = az rest --method PUT --url "https://management.azure.com/providers/Microsoft.Management/managementGroups/$($parent_management_group_id)?api-version=2020-05-01" --body $mgBodyJson --headers 'Content-Type=application/json'
    if ($LASTEXITCODE -ieq 0) {
        $parentMgName = $parent_management_group_id
        $parentMgDisplayName = $parent_management_group_display_name
        $parentMgId = "/providers/Microsoft.Management/managementGroups/$parent_management_group_id"
        $parentMgStatus = "Existing"
        $parentAction = "Created"
    }
    else {
        exit 1
    }
}

# output for external data source
@{
    tenant_root_management_group_id      = $tenantRootMgId
    tenant_root_backfill_status          = $tenantRootBackfillStatus
    parent_management_group_name         = $parentMgName
    parent_management_group_display_name = $parentMgDisplayName
    parent_management_group_id           = $parentMgId
    parent_management_group_status       = $parentMgStatus
    parent_management_group_action       = $parentAction
} | ConvertTo-Json

  SCRIPT
  ]
}

resource "time_sleep" "ecp_parent_mg_check" {
  create_duration = data.external.ecp_parent_mg_check.result.parent_management_group_action == "Created" ? "2m" : "1ms"
}

resource "azurerm_management_group" "ecp_deployment_parent" {
  provider = azurerm.launchpad

  name         = "ecp-deployment-${var.ecp_environment_name}"
  display_name = var.ecp_environment_name

  parent_management_group_id = "/providers/Microsoft.Management/managementGroups/${var.ecp_azure_root_parent_management_group_id}"

  subscription_ids = []

  lifecycle {
    ignore_changes = [
      subscription_ids
    ]
  }

  depends_on = [
    data.external.ecp_parent_mg_check,
    time_sleep.ecp_parent_mg_check
  ]
}

resource "time_sleep" "ecp_deployment_parent" {
  create_duration = "60s"

  depends_on = [
    azurerm_management_group.ecp_deployment_parent
  ]
}
