output "backend_resource_group" {
  description = "Simulated (future) terraform backend resource group"
  value = {
    id       = "/subscriptions/${data.azurerm_client_config.this.subscription_id}/Microsoft.Resources/resourceGroups/${data.azurecaf_name.rg.result}"
    name     = data.azurecaf_name.rg.result
    location = var.azure_location
  }
}

output "backend_storage_accounts" {
  description = "Simulated (future) terraform backend storage accounts created for each ECP deployment level"
  value = {
    for key in local.backend_levels : key => {
      id                  = "/subscriptions/${data.azurerm_client_config.this.subscription_id}/Microsoft.Resources/resourceGroups/${data.azurecaf_name.rg.result}/providers/Microsoft.Storage/storageAccounts/${format("%s%s", data.azurecaf_name.st.result, key)}"
      name                = format("%s%s", data.azurecaf_name.st.result, key)
      resource_group_name = data.azurecaf_name.rg.result
      location            = var.azure_location
      # # include information required for private endpoint access without DNS
      # private_endpoint_blob = {
      #   fqdn               =
      #   private_ip_address =
      #   subresource_names  =
      #   subnet_id          =
      # }
      ecp_level            = key
      tf_backend_container = "tfstate"
    }
  }
}
