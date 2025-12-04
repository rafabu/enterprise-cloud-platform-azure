# new Entra tenants will not have been enabled for using management groups
#     TenantBackfill is required. See
#     https://learn.microsoft.com/en-us/cli/azure/account/management-group/tenant-backfill?view=azure-cli-latest

resource "terraform_data" "root_management_group_structure" {
  triggers_replace = {
    tenant_id  = data.azuread_client_config.this.tenant_id
    ecp_parent = var.ecp_azure_root_parent_management_group_id
  }

  provisioner "local-exec" {
    when        = create
    interpreter = ["pwsh", "-NoLogo", "-NonInteractive", "-ExecutionPolicy", "RemoteSigned", "-command"]
    command     = <<-SCRIPT

$parent_management_group_id = "${var.ecp_azure_root_parent_management_group_id}"
$parent_management_group_display_name = "ECP Root Management Group"
$tenant_id = "${data.azuread_client_config.this.tenant_id}"

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
            Write-Output "INFO: TenantBackfill completed successfully"
            return @{ Success = $true; Status = $bfStatus }
        }
        elseif ($status -ine "Started") {
            Write-Warning "WARNING: TenantBackfill status is '$status' - unexpected state"
            return @{ Success = $false; Status = $bfStatus }
        }
        
        $elapsed = [int]((Get-Date) - $startTime).TotalMinutes
        Write-Output "INFO: TenantBackfill in progress... (elapsed: $elapsed min)"
    }
    
    Write-Warning "WARNING: TenantBackfill did not complete within $MaxWaitMinutes minutes"
    return @{ Success = $false; Status = $null }
}

# check if root management group already exists (backfill had happened in the past)
$bfStatus = az rest --method POST --url "https://management.azure.com/providers/Microsoft.Management/tenantBackfillStatus?api-version=2020-05-01"
if ($bfStatus -and ($bfStatus | ConvertFrom-Json).status -ieq "Completed") {
    Write-Output "INFO: Root Management Group exists - TenantBackfill has already been completed for this tenant."
}
elseif ($bfStatus -and ($bfStatus | ConvertFrom-Json).status -ieq "Started") {
    Write-Output "INFO: Root Management Group is being created - TenantBackfill is in progress for this tenant."
    $result = Wait-TenantBackfill -MaxWaitMinutes 10 -PollIntervalSeconds 15
    if ($result.Success) {
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
    }
    else {
        exit 1
    }
}

# Check if parent management group already exists
Write-Output "INFO: Checking if ECP parent management group '$parent_management_group_id' exists..."
$existingMgs = az rest --method GET --url "https://management.azure.com/providers/Microsoft.Management/managementGroups?api-version=2020-05-01" | ConvertFrom-Json
$existingMg = $existingMgs.value | Where-Object { $_.name -ieq $parent_management_group_id } | Select-Object -First 1

if ($existingMg) {
    Write-Output "      Management group '$parent_management_group_id' already exists"
    Write-Output "        Display Name: $($existingMg.properties.displayName)"
    Write-Output "        ID: $($existingMg.id)"
    exit 0
}
else {
    Write-Output "INFO: ECP parent management group '$parent_management_group_id' not found - creating..."
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
        $created = $createResult | ConvertFrom-Json
        Write-Output "      ECP parent management group created successfully"
        Write-Output "        Name:         $($created.name)"
        Write-Output "        Display Name: $parent_management_group_display_name"
        Write-Output "        ID:           $($created.id)"
        exit 0
    }
    else {
        Write-Error "ERROR: Failed to create management group '$parent_management_group_id'"
        exit 1
    }
}

SCRIPT
  }
}

resource "azurerm_management_group" "ecp_deployment_parent" {

  name         = "ECP-Deployment-${var.ecp_environment_name}"
  display_name = var.ecp_environment_name

  parent_management_group_id = var.ecp_azure_root_parent_management_group_id

  subscription_ids = []

  lifecycle {
    ignore_changes = [
      subscription_ids
    ]
  }
}
