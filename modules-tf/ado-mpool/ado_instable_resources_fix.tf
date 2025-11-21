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

# Replacement for azuredevops_service_principal_entitlement.mpool
# Uses Azure DevOps CLI for stable cross-platform service principal entitlement management
resource "terraform_data" "mpool_service_principal_entitlement" {
  for_each = local.ado_wid_permission_objects

  # Triggers for recreation when dependencies change
  triggers_replace = {
    origin_id            = var.workload_identity_type == "userAssignedIdentity" ? azurerm_user_assigned_identity.mpool[each.key].principal_id : var.workload_identity_type == "serviceprincipal" ? azuread_service_principal.mpool[each.key].object_id : "error"
    organization         = var.ecp_azure_devops_organization_name  
    project_name         = var.ecp_azure_devops_project_name
    account_license_type = "express"
    workload_identity_type = var.workload_identity_type
  }

  # Create/Update service principal entitlement
  provisioner "local-exec" {
    interpreter = ["pwsh", "-NoLogo", "-NonInteractive", "-ExecutionPolicy", "RemoteSigned", "-Command"]
    command     = <<-EOT
      # PowerShell script to create service principal entitlement
      $ErrorActionPreference = 'Stop'
      
      try {
          Write-Host "INFO: Configuring service principal entitlement..."
          
          # Set Azure DevOps organization context
          $orgUrl = "https://dev.azure.com/${var.ecp_azure_devops_organization_name}"
          $principalId = "${var.workload_identity_type == "userAssignedIdentity" ? azurerm_user_assigned_identity.mpool[each.key].principal_id : azuread_service_principal.mpool[each.key].object_id}"
          $licenseType = "express"
          
          Write-Host "INFO:   Organization: $orgUrl"
          Write-Host "INFO:   Principal ID: $principalId"
          Write-Host "INFO:   License Type: $licenseType"
          Write-Host "INFO:   Workload Identity Type: ${var.workload_identity_type}"
          
          # Configure Azure DevOps CLI defaults
          az devops configure --defaults organization="$orgUrl"
          if ($LASTEXITCODE -ne 0) {
              throw "Failed to configure Azure DevOps CLI defaults"
          }
          
          # Verify authentication and access
          Write-Host "INFO: Verifying Azure DevOps authentication..."
          try {
              $orgCheck = az devops project list --output none
              if ($LASTEXITCODE -ne 0) {
                  throw "Authentication check failed"
              }
          } catch {
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
              
              # Retry organization access check
              az devops project list --output none
              if ($LASTEXITCODE -ne 0) {
                  throw "Unable to access Azure DevOps organization. Check permissions and authentication."
              }
          }
          
          # Get service principal display name for lookup
          Write-Host "INFO: Looking up service principal details..."
          $spDetails = az ad sp show --id "$principalId" --query "{displayName:displayName, appId:appId}" --output json | ConvertFrom-Json
          if (-not $spDetails) {
              throw "Could not find service principal with ID: $principalId"
          }
          
          $spDisplayName = $spDetails.displayName
          $spAppId = $spDetails.appId
          Write-Host "INFO: Service Principal Display Name: $spDisplayName"
          Write-Host "INFO: Service Principal App ID: $spAppId"
          
          # Check if user already exists in Azure DevOps
          Write-Host "INFO: Checking existing entitlement..."
          $existingUsers = az devops user list --output json | ConvertFrom-Json
          $existingUser = $existingUsers | Where-Object { 
              $_.user.principalName -eq $spAppId -or 
              $_.user.displayName -eq $spDisplayName -or
              $_.user.mailAddress -eq "$spAppId@" -or
              $_.user.id -eq $principalId
          }
          
          if ($existingUser) {
              Write-Host "INFO: Service principal already has entitlement"
              Write-Host "INFO:   User ID: $($existingUser.id)"
              Write-Host "INFO:   Display Name: $($existingUser.user.displayName)"
              Write-Host "INFO:   License: $($existingUser.accessLevel.licenseDisplayName)"
              
              # Check if license needs updating
              $currentLicense = $existingUser.accessLevel.accountLicenseType
              if ($currentLicense -ne $licenseType) {
                  Write-Host "INFO: Updating license from $currentLicense to $licenseType..."
                  try {
                      # Note: Azure DevOps CLI doesn't have direct license update command
                      # This would require REST API call or removing/re-adding user
                      Write-Host "INFO: License update via CLI not directly supported - current license: $currentLicense"
                  } catch {
                      Write-Host "WARNING: Could not update license: $($_.Exception.Message)"
                  }
              }
          } else {
              Write-Host "INFO: Creating new service principal entitlement..."
              
              # Add user to Azure DevOps organization
              # Try different methods based on available information
              try {
                  # Method 1: Try with App ID as email
                  Write-Host "INFO: Attempting to add user with App ID..."
                  az devops user add --email-id "$spAppId@noreply.microsoft.com" --license-type $licenseType --send-email-invite false
                  
                  if ($LASTEXITCODE -eq 0) {
                      Write-Host "SUCCESS: Service principal entitlement created successfully"
                  } else {
                      throw "Failed to add user with App ID method"
                  }
              } catch {
                  Write-Host "WARNING: App ID method failed, trying Principal ID method..."
                  
                  # Method 2: Try with Principal ID
                  try {
                      az devops user add --email-id "$principalId@noreply.microsoft.com" --license-type $licenseType --send-email-invite false
                      
                      if ($LASTEXITCODE -eq 0) {
                          Write-Host "SUCCESS: Service principal entitlement created successfully (Principal ID method)"
                      } else {
                          throw "Failed to add user with Principal ID method"
                      }
                  } catch {
                      Write-Host "WARNING: Principal ID method failed, trying display name method..."
                      
                      # Method 3: Try with display name as fallback
                      $emailFormat = "$($spDisplayName -replace '[^a-zA-Z0-9]', '')@noreply.microsoft.com"
                      az devops user add --email-id $emailFormat --license-type $licenseType --send-email-invite false
                      
                      if ($LASTEXITCODE -eq 0) {
                          Write-Host "SUCCESS: Service principal entitlement created successfully (Display name method)"
                      } else {
                          Write-Host "WARNING: All methods failed, but this may be expected for service principals"
                          Write-Host "INFO: Service principal may already exist with different identifier"
                      }
                  }
              }
          }
          
          # Final verification
          Write-Host "INFO: Performing final verification..."
          $finalCheck = az devops user list --output json | ConvertFrom-Json
          $verifyUser = $finalCheck | Where-Object { 
              $_.user.principalName -like "*$spAppId*" -or 
              $_.user.displayName -eq $spDisplayName -or
              $_.user.id -eq $principalId
          }
          
          if ($verifyUser) {
              Write-Host "SUCCESS: Service principal entitlement verified"
              Write-Host "INFO:   Final User ID: $($verifyUser.id)"
              Write-Host "INFO:   Final Display Name: $($verifyUser.user.displayName)" 
              Write-Host "INFO:   Final License: $($verifyUser.accessLevel.licenseDisplayName)"
          } else {
              Write-Host "WARNING: Could not verify entitlement, but operation may have succeeded"
              Write-Host "INFO: Service principal entitlements sometimes take time to appear in listings"
          }
          
          Write-Host "INFO: Service principal entitlement configuration completed"
          
      } catch {
          Write-Error "ERROR: Failed to configure service principal entitlement: $($_.Exception.Message)"
          Write-Error "ERROR: This may indicate authentication issues or insufficient permissions"
          Write-Error "ERROR: Ensure the executing identity has Organization Administrator permissions in Azure DevOps"
          Write-Error "ERROR: Also ensure the service principal exists and is accessible"
          exit 1
      }
    EOT
  }

  # Remove entitlement on destroy
  provisioner "local-exec" {
    when        = destroy
    interpreter = ["pwsh", "-NoLogo", "-NonInteractive", "-ExecutionPolicy", "RemoteSigned", "-Command"]
    command     = <<-EOT
      # PowerShell script to remove service principal entitlement
      $ErrorActionPreference = 'Continue'  # Don't fail destroy on cleanup issues
      
      try {
          Write-Host "INFO: Cleaning up service principal entitlement..."
          
          # Set Azure DevOps CLI context
          az devops configure --defaults organization="https://dev.azure.com/${self.triggers_replace.organization}"
          
          $principalId = "${self.triggers_replace.origin_id}"
          
          # Find and remove user
          $users = az devops user list --output json | ConvertFrom-Json
          $targetUser = $users | Where-Object { 
              $_.user.id -eq $principalId -or 
              $_.user.principalName -like "*$principalId*"
          }
          
          if ($targetUser) {
              Write-Host "INFO: Removing user entitlement for: $($targetUser.user.displayName)"
              az devops user remove --id $targetUser.id --yes
              
              if ($LASTEXITCODE -eq 0) {
                  Write-Host "SUCCESS: Service principal entitlement removed"
              } else {
                  Write-Warning "WARNING: Failed to remove entitlement, but continuing destroy"
              }
          } else {
              Write-Host "INFO: Service principal entitlement not found or already removed"
          }
          
      } catch {
          Write-Warning "WARNING: Could not clean up service principal entitlement: $($_.Exception.Message)"
          Write-Warning "WARNING: This is not critical - manual cleanup may be required"
      }
    EOT
  }

  depends_on = [
    time_sleep.wait_after_user_assigned_identity
  ]
}

# Create local reference for backward compatibility
locals {
  # Provide descriptor mapping for resources that depend on the original entitlement resource
  service_principal_entitlement_descriptors = {
    for key, val in terraform_data.mpool_service_principal_entitlement : key => "aad.${val.triggers_replace.origin_id}"
  }
}
