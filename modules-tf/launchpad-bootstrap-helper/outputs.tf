output "backend_resource_group" {
  description = "Simulated (future) terraform backend resource group"
  value = {
    id       = provider::azurerm::normalise_resource_id("$data.azurerm_client_config.this.id}/Microsoft.Resources/resourceGroups/${data.azurecaf_name.rg.result}")
    name     = data.azurecaf_name.rg.result
    location = var.azure_location
  }
}

output "backend_storage_accounts" {
  description = "Simulated (future) terraform backend storage accounts created for each ECP deployment level"
  value = {
    for key in local.backend_levels : key => {
      id                  = provider::azurerm::normalise_resource_id("$data.azurerm_client_config.this.id}/Microsoft.Resources/resourceGroups/${data.azurecaf_name.rg.result}/providers/Microsoft.Storage/storageAccounts/${format("%s%s", data.azurecaf_name.st.result, key)}")
      name                = format("%s%s", data.azurecaf_name.st.result, each.key)
      resource_group_name = data.azurecaf_name.rg.result
      location            = var.azure_location
      # # include information required for private endpoint access without DNS
      # private_endpoint_blob = {
      #   fqdn               = azurerm_private_endpoint.backend_blob[key].custom_dns_configs[0].fqdn
      #   private_ip_address = azurerm_private_endpoint.backend_blob[key].private_service_connection[0].private_ip_address
      #   subresource_names  = azurerm_private_endpoint.backend_blob[key].private_service_connection[0].subresource_names
      #   subnet_id          = azurerm_private_endpoint.backend_blob[key].subnet_id
      # }
      ecp_level            = key
      tf_backend_container = "tfstate"
    }
  }
}
