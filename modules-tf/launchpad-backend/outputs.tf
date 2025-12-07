output "resource_group" {
  description = "Terraform backend resource group"
  value = {
    id       = azurerm_resource_group.backend.id
    name     = azurerm_resource_group.backend.name
    location = azurerm_resource_group.backend.location
  }
}

output "storage_accounts" {
  description = "Terraform backend storage accounts created for each ECP deployment level"
  value = {
    for key, val in azurerm_storage_account.backend : key => {
      subscription_id     = data.azurerm_client_config.this.subscription_id
      resource_group_name = val.resource_group_name
      id                  = val.id
      name                = val.name
      location            = val.location
      # include information required for private endpoint access without DNS
      private_endpoint_blob = {
        fqdn               = azurerm_private_endpoint.backend_blob[key].custom_dns_configs[0].fqdn
        private_ip_address = azurerm_private_endpoint.backend_blob[key].private_service_connection[0].private_ip_address
        subresource_names  = azurerm_private_endpoint.backend_blob[key].private_service_connection[0].subresource_names
        subnet_id          = azurerm_private_endpoint.backend_blob[key].subnet_id
      }
      ecp_level            = key
      tf_backend_container = azapi_resource.tfstate_container[key].name

    }
  }
}

