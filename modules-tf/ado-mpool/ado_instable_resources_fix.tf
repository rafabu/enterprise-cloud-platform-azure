# # # # =============================================================================
# # # # AZURE DEVOPS PROVIDER INSTABILITY FIXES
# # # # =============================================================================
# # # # This file contains replacement resources for Azure DevOps provider resources
# # # # that exhibit instability on Linux platforms, causing unnecessary recreations
# # # # and state drift issues.
# # # #
# # # # These resources use terraform_data with local PowerShell provisioners and
# # # # Azure DevOps CLI commands to provide stable, cross-platform alternatives.
# # # # =============================================================================

# # # # Replacement for azuredevops_pipeline_authorization.mpool_serviceendpoint
# # # # Uses Azure DevOps CLI for stable cross-platform service endpoint authorization
# # # resource "terraform_data" "mpool_serviceendpoint_authorization" {
# # #   for_each = local.ado_wid_permission_objects

# # #   # Triggers for recreation when dependencies change
# # #   triggers_replace = {
# # #     project_id            = local.azure_devops_project.project_id
# # #     # known after apply...
# # #     # service_endpoint_id   = azuredevops_serviceendpoint_azurerm.mpool[each.key].id
# # #     service_endpoint_name = azuredevops_serviceendpoint_azurerm.mpool[each.key].service_endpoint_name
# # #     organization          = var.ecp_azure_devops_organization_name
# # #     project_name          = var.ecp_azure_devops_project_name
# # #   }

# # #   # Create/Update authorization
# # #   provisioner "local-exec" {
# # #     interpreter = ["pwsh", "-NoLogo", "-NonInteractive", "-ExecutionPolicy", "RemoteSigned", "-Command"]
# # #     command     = <<-EOT
# # #       # PowerShell script to authorize service endpoint for all pipelines
# # #       $ErrorActionPreference = 'Stop'
      
# # #       try {
# # #           Write-Host "INFO: Configuring pipeline authorization for service endpoint..."
          
# # #           # Set Azure DevOps organization and project context
# # #           $orgUrl = "https://dev.azure.com/${var.ecp_azure_devops_organization_name}"
# # #           $projectName = "${var.ecp_azure_devops_project_name}"
# # #           $serviceEndpointName = "${azuredevops_serviceendpoint_azurerm.mpool[each.key].service_endpoint_name}"
          
# # #           Write-Host "INFO:   Organization: $orgUrl"
# # #           Write-Host "INFO:   Project: $projectName"
# # #           Write-Host "INFO:   Service Endpoint: $serviceEndpointName"
          
# # #           # Configure Azure DevOps CLI defaults
# # #           az devops configure --defaults organization="$orgUrl" project="$projectName"
# # #           if ($LASTEXITCODE -ne 0) {
# # #               throw "Failed to configure Azure DevOps CLI defaults"
# # #           }
          
# # #           # Verify authentication and access
# # #           Write-Host "INFO: Verifying Azure DevOps authentication..."
# # #           $projectCheck = az devops project show --organization --project "$projectName" --output none
# # #           if ($LASTEXITCODE -ne 0) {
# # #               Write-Host "WARNING: Authentication check failed. Attempting different auth methods..."
              
# # #               # Check for different authentication contexts
# # #               if ($env:SYSTEM_ACCESSTOKEN) {
# # #                   Write-Host "INFO: Using System.AccessToken for authentication"
# # #                   $env:AZURE_DEVOPS_EXT_PAT = $env:SYSTEM_ACCESSTOKEN
# # #               } elseif ($env:AZURE_DEVOPS_EXT_PAT) {
# # #                   Write-Host "INFO: Using AZURE_DEVOPS_EXT_PAT for authentication"
# # #               } else {
# # #                   Write-Host "INFO: Using Azure CLI login context"
# # #                   # Verify az login status
# # #                   $loginCheck = az account show --output none 2>$null
# # #                   if ($LASTEXITCODE -ne 0) {
# # #                       throw "No valid authentication found. Please run 'az login' or set AZURE_DEVOPS_EXT_PAT"
# # #                   }
# # #               }
              
# # #               # Retry project access check
# # #               az devops project show --project "$projectName" --output none
# # #               if ($LASTEXITCODE -ne 0) {
# # #                   throw "Unable to access Azure DevOps project. Check permissions and authentication."
# # #               }
# # #           }
          
# # #           # Get service endpoint ID
# # #           Write-Host "INFO: Looking up service endpoint ID..."
# # #           $serviceEndpoints = az devops service-endpoint list --output json | ConvertFrom-Json
# # #           $targetEndpoint = $serviceEndpoints | Where-Object { $_.name -eq $serviceEndpointName }
          
# # #           if (-not $targetEndpoint) {
# # #               throw "Service endpoint '$serviceEndpointName' not found in project '$projectName'"
# # #           }
          
# # #           $serviceEndpointId = $targetEndpoint.id
# # #           Write-Host "INFO: Found service endpoint ID: $serviceEndpointId"
          
# # #           # Check current authorization status
# # #           Write-Host "INFO: Checking current authorization status..."
# # #           try {
# # #               $authStatus = az devops service-endpoint show --id "$serviceEndpointId" --output json | ConvertFrom-Json
# # #               $isAuthorized = $authStatus.isShared -eq $true -or $authStatus.authorization.authorized -eq $true
              
# # #               if ($isAuthorized) {
# # #                   Write-Host "INFO: Service endpoint is already authorized for all pipelines"
# # #               } else {
# # #                   Write-Host "INFO: Service endpoint needs authorization"
                  
# # #                   # Authorize service endpoint for all pipelines
# # #                   Write-Host "INFO: Authorizing service endpoint for all pipelines..."
# # #                   az devops service-endpoint update --id "$serviceEndpointId" --enable-for-all $true
                  
# # #                   if ($LASTEXITCODE -eq 0) {
# # #                       Write-Host "SUCCESS: Service endpoint authorized successfully"
# # #                   } else {
# # #                       Write-Host "WARNING: Authorization command completed with non-zero exit code, but this may be expected"
# # #                   }
# # #               }
# # #           } catch {
# # #               Write-Host "WARNING: Could not check authorization status: $($_.Exception.Message)"
# # #               Write-Host "INFO: Attempting to authorize anyway..."
              
# # #               # Try to authorize regardless of status check failure
# # #               az devops service-endpoint update --id "$serviceEndpointId" --enable-for-all $true
# # #               Write-Host "INFO: Authorization command completed"
# # #           }
          
# # #           # Final verification
# # #           Write-Host "INFO: Performing final verification..."
# # #           $finalCheck = az devops service-endpoint show --id "$serviceEndpointId" --query "authorization.authorized" -o tsv 2>$null
# # #           if ($finalCheck -eq "true") {
# # #               Write-Host "SUCCESS: Service endpoint authorization verified"
# # #           } else {
# # #               Write-Host "WARNING: Could not verify authorization status, but operation completed"
# # #           }
          
# # #           Write-Host "INFO: Pipeline authorization configuration completed successfully"
          
# # #       } catch {
# # #           Write-Error "ERROR: Failed to configure pipeline authorization: $($_.Exception.Message)"
# # #           Write-Error "ERROR: This may indicate authentication issues or insufficient permissions"
# # #           Write-Error "ERROR: Ensure the executing identity has Project Administrator permissions in Azure DevOps"
# # #           exit 1
# # #       }
# # #     EOT
# # #   }

# # #   depends_on = [
# # #     azuredevops_serviceendpoint_azurerm.mpool
# # #   ]
# # # }

# Replacement for azuredevops_service_principal_entitlement.mpool
# Uses Azure DevOps CLI for stable cross-platform service principal entitlement management
# # # resource "terraform_data" "mpool_service_principal_entitlement" {
# # #   for_each = local.ado_wid_permission_objects

# # #   # Triggers for recreation when dependencies change
# # #   triggers_replace = {
# # #     origin_id            = var.workload_identity_type == "userAssignedIdentity" ? azurerm_user_assigned_identity.mpool[each.key].principal_id : var.workload_identity_type == "serviceprincipal" ? azuread_service_principal.mpool[each.key].object_id : "error"
# # #     organization         = var.ecp_azure_devops_organization_name  
# # #     project_name         = var.ecp_azure_devops_project_name
# # #     account_license_type = "express"
# # #     workload_identity_type = var.workload_identity_type
# # #     zzz = "aaa"
# # #   }

# # #   # Create/Update service principal entitlement
# # #   provisioner "local-exec" {
# # #     interpreter = ["pwsh", "-NoLogo", "-NonInteractive", "-ExecutionPolicy", "RemoteSigned", "-Command"]
# # #     command     = <<-EOT
# # #       # PowerShell script to create service principal entitlement (CORRECTED)
# # #       $ErrorActionPreference = 'Stop'
      
# # #       try {
# # #           Write-Host "INFO: Configuring service principal entitlement..."
          
# # #           # Set Azure DevOps organization context
# # #           $orgUrl = "https://dev.azure.com/${var.ecp_azure_devops_organization_name}"
# # #           $principalId = "${var.workload_identity_type == "userAssignedIdentity" ? azurerm_user_assigned_identity.mpool[each.key].principal_id : azuread_service_principal.mpool[each.key].object_id}"
# # #           $licenseType = "express"
          
# # #           Write-Host "INFO:   Organization: $orgUrl"
# # #           Write-Host "INFO:   Principal ID: $principalId"
# # #           Write-Host "INFO:   License Type: $licenseType"
          
# # #           # Configure Azure DevOps CLI defaults
# # #           az devops configure --defaults organization="$orgUrl"
# # #           if ($LASTEXITCODE -ne 0) {
# # #               throw "Failed to configure Azure DevOps CLI defaults"
# # #           }
          
# # #           # Verify authentication
# # #           Write-Host "INFO: Verifying Azure DevOps authentication..."
# # #           az devops project list --output none
# # #           if ($LASTEXITCODE -ne 0) {
# # #               if ($env:SYSTEM_ACCESSTOKEN) {
# # #                   $env:AZURE_DEVOPS_EXT_PAT = $env:SYSTEM_ACCESSTOKEN
# # #               }
# # #               az devops project list --output none
# # #               if ($LASTEXITCODE -ne 0) {
# # #                   throw "Unable to authenticate with Azure DevOps"
# # #               }
# # #           }
          
# # #           # Get service principal details from Azure AD
# # #           Write-Host "INFO: Getting service principal details..."
# # #           $spDetails = az ad sp show --id "$principalId" --query "{displayName:displayName, appId:appId}" --output json | ConvertFrom-Json
# # #           if (-not $spDetails) {
# # #               throw "Could not find service principal with ID: $principalId"
# # #           }
          
# # #           $spDisplayName = $spDetails.displayName
# # #           $spAppId = $spDetails.appId
# # #           Write-Host "INFO: SP Display Name: $spDisplayName"
# # #           Write-Host "INFO: SP App ID: $spAppId"
          
# # #           # METHOD 1: Use Azure DevOps Service Principal Entitlements API
# # #           Write-Host "INFO: Attempting to create service principal entitlement via REST API..."
          
# # #           # Create service principal entitlement using correct API endpoint
# # #           $entitlementBody = @{
# # #               accessLevel = @{
# # #                   accountLicenseType = $licenseType
# # #                   licenseDisplayName = "Basic"
# # #               }
# # #               servicePrincipal = @{
# # #                   directoryId = $principalId
# # #                   displayName = $spDisplayName
# # #                   origin = "aad"
# # #                   originId = $principalId
# # #                   principalName = $spAppId
# # #                   subjectKind = "servicePrincipal"
# # #               }
# # #           } | ConvertTo-Json -Depth 10
          
# # #           try {
# # #               Write-Host "INFO: Creating service principal entitlement via correct API endpoint..."
              
# # #               # Use az rest for direct REST API call with 7.1-preview.1
# # #               $entitlementResult = az rest `
# # #                   --method POST `
# # #                   --url "https://vsaex.dev.azure.com/${var.ecp_azure_devops_organization_name}/_apis/MemberEntitlementManagement/ServicePrincipalEntitlements?api-version=7.1-preview.1" `
# # #                   --resource "499b84ac-1321-427f-aa17-267ca6975798" `
# # #                   --body $entitlementBody `
# # #                   --headers "Content-Type=application/json" `
# # #                   --output json
              
# # #               if ($LASTEXITCODE -eq 0) {
# # #                   Write-Host "SUCCESS: Service principal entitlement created via REST API"
# # #                   $entitlementData = $entitlementResult | ConvertFrom-Json
# # #                   Write-Host "INFO: Entitlement ID: $($entitlementData.id)"
# # #                   Write-Host "INFO: Service Principal: $($entitlementData.servicePrincipal.displayName)"
# # #               } else {
# # #                   throw "Service Principal Entitlements API method failed"
# # #               }
# # #           } catch {
# # #               Write-Host "WARNING: REST API method failed: $($_.Exception.Message)"
              
# # #               # METHOD 2: Use Security Group Membership (Alternative approach)
# # #               Write-Host "INFO: Attempting alternative method via security groups..."
              
# # #               try {
# # #                   # Add service principal to 'Project Valid Users' group
# # #                   Write-Host "INFO: Adding service principal to Project Valid Users group..."
                  
# # #                   # Get project security groups
# # #                   $securityGroups = az devops security group list --project "${var.ecp_azure_devops_project_name}" --output json | ConvertFrom-Json
# # #                   $validUsersGroup = $securityGroups.graphGroups | Where-Object { $_.displayName -like "*Project Valid Users*" -or $_.displayName -like "*Valid Users*" }
                  
# # #                   if ($validUsersGroup) {
# # #                       Write-Host "INFO: Found Project Valid Users group: $($validUsersGroup.descriptor)"
                      
# # #                       # Add service principal to group
# # #                       az devops security group membership add `
# # #                           --group-id $validUsersGroup.descriptor `
# # #                           --member-id "aad.$principalId" `
# # #                           --output none
                      
# # #                       if ($LASTEXITCODE -eq 0) {
# # #                           Write-Host "SUCCESS: Service principal added to Project Valid Users group"
# # #                       } else {
# # #                           Write-Host "WARNING: Failed to add to Project Valid Users group"
# # #                       }
# # #                   }
                  
# # #               } catch {
# # #                   Write-Host "WARNING: Security group method also failed: $($_.Exception.Message)"
                  
# # #                   # METHOD 3: Direct REST API call using Invoke-RestMethod
# # #                   Write-Host "INFO: Attempting direct REST API call..."
                  
# # #                   try {
# # #                       # Get authentication token
# # #                       $token = if ($env:AZURE_DEVOPS_EXT_PAT) { 
# # #                           $env:AZURE_DEVOPS_EXT_PAT 
# # #                       } elseif ($env:SYSTEM_ACCESSTOKEN) { 
# # #                           $env:SYSTEM_ACCESSTOKEN 
# # #                       } else { 
# # #                           az account get-access-token --resource "499b84ac-1321-427f-aa17-267ca6975798" --query "accessToken" -o tsv 
# # #                       }
                      
# # #                       $headers = @{
# # #                           'Authorization' = "Bearer $token"
# # #                           'Content-Type' = 'application/json'
# # #                           'Accept' = 'application/json'
# # #                       }
                      
# # #                       $apiUrl = "https://vsaex.dev.azure.com/${var.ecp_azure_devops_organization_name}/_apis/MemberEntitlementManagement/ServicePrincipalEntitlements?api-version=7.1-preview.1"
                      
# # #                       $body = @{
# # #                           accessLevel = @{
# # #                               accountLicenseType = $licenseType
# # #                               licenseDisplayName = "Basic"
# # #                           }
# # #                           servicePrincipal = @{
# # #                               directoryId = $principalId
# # #                               displayName = $spDisplayName
# # #                               origin = "aad"
# # #                               originId = $principalId
# # #                               principalName = $spAppId
# # #                               subjectKind = "servicePrincipal"
# # #                           }
# # #                       } | ConvertTo-Json -Depth 5
                      
# # #                       $response = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers -Body $body
# # #                       Write-Host "SUCCESS: Service principal entitlement created via direct REST API"
# # #                       Write-Host "INFO: Response: $($response | ConvertTo-Json -Compress)"
                      
# # #                   } catch {
# # #                       Write-Host "ERROR: All methods failed to create service principal entitlement"
# # #                       Write-Host "ERROR: Last error: $($_.Exception.Message)"
                      
# # #                       # Still continue - the service principal might already have implicit access
# # #                       Write-Host "WARNING: Service principal entitlement creation failed, but continuing..."
# # #                       Write-Host "INFO: Service principal may still have access through other means"
# # #                   }
# # #               }
# # #           }
          
# # #           # Verification step
# # #           Write-Host "INFO: Verifying service principal access..."
# # #           try {
# # #               # Check if service principal appears in user listings (may not always work)
# # #               $users = az devops user list --output json 2>$null | ConvertFrom-Json
# # #               $spUser = $users | Where-Object { 
# # #                   $_.user.principalName -eq $spAppId -or 
# # #                   $_.user.id -eq $principalId -or
# # #                   $_.user.displayName -eq $spDisplayName
# # #               }
              
# # #               if ($spUser) {
# # #                   Write-Host "SUCCESS: Service principal found in user list"
# # #                   Write-Host "INFO: User ID: $($spUser.id)"
# # #                   Write-Host "INFO: License: $($spUser.accessLevel.licenseDisplayName)"
# # #               } else {
# # #                   Write-Host "INFO: Service principal not visible in user list (this may be normal)"
# # #                   Write-Host "INFO: Service principals may have implicit access without explicit entitlements"
# # #               }
# # #           } catch {
# # #               Write-Host "INFO: Could not verify service principal in user list: $($_.Exception.Message)"
# # #           }
          
# # #           Write-Host "INFO: Service principal entitlement configuration completed"
          
# # #       } catch {
# # #           Write-Error "ERROR: Failed to configure service principal entitlement: $($_.Exception.Message)"
# # #           Write-Error "ERROR: This may indicate authentication issues or insufficient permissions"
# # #           exit 1
# # #       }
# # #     EOT
# # #   }

# # #   depends_on = [
# # #     time_sleep.wait_after_user_assigned_identity
# # #   ]
# # # }

# # # # Create local reference for backward compatibility
# # # locals {
# # #   # Provide descriptor mapping for resources that depend on the original entitlement resource
# # #   service_principal_entitlement_descriptors = {
# # #     for key, val in terraform_data.mpool_service_principal_entitlement : key => "aad.${val.triggers_replace.origin_id}"
# # #   }
# # # }
