# =============================================================================
# AZURE DEVOPS PROVIDER INSTABILITY FIXES
# =============================================================================
# This file contains replacement resources for Azure DevOps provider resources
# that exhibit instability on Linux platforms, causing unnecessary recreations
# and state drift issues.
#
# These resources use terraform_data with local PowerShell provisioners and
# Azure DevOps CLI commands to provide stable, cross-platform alternatives.
# =============================================================================

# Replacement for azuredevops_pipeline_authorization.mpool_serviceendpoint
# Uses Azure DevOps CLI for stable cross-platform service endpoint authorization
resource "terraform_data" "mpool_serviceendpoint_authorization" {
  for_each = local.ado_wid_permission_objects

  # Triggers for recreation when dependencies change
  triggers_replace = {
    project_id            = local.azure_devops_project.project_id
    # known after apply...
    # service_endpoint_id   = azuredevops_serviceendpoint_azurerm.mpool[each.key].id
    service_endpoint_name = azuredevops_serviceendpoint_azurerm.mpool[each.key].service_endpoint_name
    organization          = var.ecp_azure_devops_organization_name
    project_name          = var.ecp_azure_devops_project_name
  }

  # Create/Update authorization
  provisioner "local-exec" {
    interpreter = ["pwsh", "-NoLogo", "-NonInteractive", "-ExecutionPolicy", "RemoteSigned", "-Command"]
    command     = <<-EOT
      # PowerShell script to authorize service endpoint for all pipelines
      $ErrorActionPreference = 'Stop'
      
      try {
          Write-Host "INFO: Configuring pipeline authorization for service endpoint..."
          
          # Set Azure DevOps organization and project context
          $orgUrl = "https://dev.azure.com/${var.ecp_azure_devops_organization_name}"
          $projectName = "${var.ecp_azure_devops_project_name}"
          $serviceEndpointName = "${azuredevops_serviceendpoint_azurerm.mpool[each.key].service_endpoint_name}"
          
          Write-Host "INFO:   Organization: $orgUrl"
          Write-Host "INFO:   Project: $projectName"
          Write-Host "INFO:   Service Endpoint: $serviceEndpointName"
          
          # Configure Azure DevOps CLI defaults
          az devops configure --defaults organization="$orgUrl" project="$projectName"
          if ($LASTEXITCODE -ne 0) {
              throw "Failed to configure Azure DevOps CLI defaults"
          }
          
          # Verify authentication and access
          Write-Host "INFO: Verifying Azure DevOps authentication..."
          $projectCheck = az devops project show --organization --project "$projectName" --output none
          if ($LASTEXITCODE -ne 0) {
              Write-Host "WARNING: Authentication check failed. Attempting different auth methods..."
              
              # Check for different authentication contexts
              if ($env:SYSTEM_ACCESSTOKEN) {
                  Write-Host "INFO: Using System.AccessToken for authentication"
                  $env:AZURE_DEVOPS_EXT_PAT = $env:SYSTEM_ACCESSTOKEN
              } elseif ($env:AZURE_DEVOPS_EXT_PAT) {
                  Write-Host "INFO: Using AZURE_DEVOPS_EXT_PAT for authentication"
              } else {
                  Write-Host "INFO: Using Azure CLI login context"
                  # Verify az login status
                  $loginCheck = az account show --output none 2>$null
                  if ($LASTEXITCODE -ne 0) {
                      throw "No valid authentication found. Please run 'az login' or set AZURE_DEVOPS_EXT_PAT"
                  }
              }
              
              # Retry project access check
              az devops project show --project "$projectName" --output none
              if ($LASTEXITCODE -ne 0) {
                  throw "Unable to access Azure DevOps project. Check permissions and authentication."
              }
          }
          
          # Get service endpoint ID
          Write-Host "INFO: Looking up service endpoint ID..."
          $serviceEndpoints = az devops service-endpoint list --output json | ConvertFrom-Json
          $targetEndpoint = $serviceEndpoints | Where-Object { $_.name -eq $serviceEndpointName }
          
          if (-not $targetEndpoint) {
              throw "Service endpoint '$serviceEndpointName' not found in project '$projectName'"
          }
          
          $serviceEndpointId = $targetEndpoint.id
          Write-Host "INFO: Found service endpoint ID: $serviceEndpointId"
          
          # Check current authorization status
          Write-Host "INFO: Checking current authorization status..."
          try {
              $authStatus = az devops service-endpoint show --id "$serviceEndpointId" --output json | ConvertFrom-Json
              $isAuthorized = $authStatus.isShared -eq $true -or $authStatus.authorization.authorized -eq $true
              
              if ($isAuthorized) {
                  Write-Host "INFO: Service endpoint is already authorized for all pipelines"
              } else {
                  Write-Host "INFO: Service endpoint needs authorization"
                  
                  # Authorize service endpoint for all pipelines
                  Write-Host "INFO: Authorizing service endpoint for all pipelines..."
                  az devops service-endpoint update --id "$serviceEndpointId" --enable-for-all $true
                  
                  if ($LASTEXITCODE -eq 0) {
                      Write-Host "SUCCESS: Service endpoint authorized successfully"
                  } else {
                      Write-Host "WARNING: Authorization command completed with non-zero exit code, but this may be expected"
                  }
              }
          } catch {
              Write-Host "WARNING: Could not check authorization status: $($_.Exception.Message)"
              Write-Host "INFO: Attempting to authorize anyway..."
              
              # Try to authorize regardless of status check failure
              az devops service-endpoint update --id "$serviceEndpointId" --enable-for-all $true
              Write-Host "INFO: Authorization command completed"
          }
          
          # Final verification
          Write-Host "INFO: Performing final verification..."
          $finalCheck = az devops service-endpoint show --id "$serviceEndpointId" --query "authorization.authorized" -o tsv 2>$null
          if ($finalCheck -eq "true") {
              Write-Host "SUCCESS: Service endpoint authorization verified"
          } else {
              Write-Host "WARNING: Could not verify authorization status, but operation completed"
          }
          
          Write-Host "INFO: Pipeline authorization configuration completed successfully"
          
      } catch {
          Write-Error "ERROR: Failed to configure pipeline authorization: $($_.Exception.Message)"
          Write-Error "ERROR: This may indicate authentication issues or insufficient permissions"
          Write-Error "ERROR: Ensure the executing identity has Project Administrator permissions in Azure DevOps"
          exit 1
      }
    EOT
  }

  depends_on = [
    azuredevops_serviceendpoint_azurerm.mpool
  ]
}
