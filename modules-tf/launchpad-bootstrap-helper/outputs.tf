output "backend_resource_group" {
  description = "Simulated (future) terraform backend resource group"
  value = {
    id              = "/subscriptions/${data.azurerm_client_config.this.subscription_id}/Microsoft.Resources/resourceGroups/${data.azurecaf_name.rg.result}"
    subscription_id = data.azurerm_client_config.this.subscription_id
    name            = data.azurecaf_name.rg.result
    location        = var.azure_location
  }
}

output "backend_storage_accounts" {
  description = "Simulated (future) terraform backend storage accounts created for each ECP deployment level. See ecp_resource_exists to determine if the storage account already exists."
  value = {
    for key in local.backend_levels : key => {
      id                                             = "/subscriptions/${data.azurerm_client_config.this.subscription_id}/Microsoft.Resources/resourceGroups/${data.azurecaf_name.rg.result}/providers/Microsoft.Storage/storageAccounts/${format("%s%s", data.azurecaf_name.st.result, key)}"
      subscription_id                                = data.azurerm_client_config.this.subscription_id
      name                                           = format("%s%s", data.azurecaf_name.st.result, key)
      resource_group_name                            = data.azurecaf_name.rg.result
      location                                       = var.azure_location
      ecp_level                                      = key
      tf_backend_container                           = "tfstate"
      ecp_resource_exists                            = length(data.azurerm_resources.backend_storage_accounts[key].resources) == 1
      ecp_terraform_backend                          = local.backend_type[key]
      ecp_terraform_backend_changed_since_last_apply = local.backend_type_changed[key]
    }
  }
}

output "actor_identity" {
  description = "Information on the Entra ID identity (user or service principal) used to perform operations"

  value = data.azuread_directory_object.this.type == "ServicePrincipal" ? {
    tenant_id                 = data.azuread_client_config.this.tenant_id
    object_id                 = data.azuread_service_principals.this.service_principals[0].object_id
    client_id                 = data.azuread_service_principals.this.service_principals[0].client_id
    display_name              = data.azuread_service_principals.this.service_principals[0].display_name
    user_principal_name       = ""
    type                      = data.azuread_service_principals.this.service_principals[0].type == "Application" ? "ServicePrincipal" : "ManagedIdentity"
    is_ecp_launchpad_identity = data.azuread_service_principals.this.service_principals[0].type == "Application" ? startswith(data.azuread_service_principals.this.service_principals[0].display_name, local.service_principal_name_begins_with) : startswith(data.azuread_service_principals.this.service_principals[0].display_name, local.managed_identity_name_begins_with)
    } : {
    tenant_id                 = data.azuread_client_config.this.tenant_id
    object_id                 = data.azuread_users.this.users[0].object_id
    client_id                 = ""
    display_name              = data.azuread_users.this.users[0].display_name
    user_principal_name       = data.azuread_users.this.users[0].user_principal_name
    type                      = data.azuread_directory_object.this.type
    is_ecp_launchpad_identity = false
  }
}

output "actor_network_information" {
  description = "Information on network the actor is connecting from"
  value = {
    public_ip                        = jsondecode(data.http.this_public_ip.response_body).ip
    local_ip                         = data.external.this_local_ip.result.local_ip
    is_local_ip_within_ecp_launchpad = local.ip_is_contained
    ecp_launchpad_network_cidr       = local.cidr_string
  }
}
