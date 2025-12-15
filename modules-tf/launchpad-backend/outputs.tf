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
        # fall back to default if custom DNS config is not present
        fqdn               = try(azurerm_private_endpoint.backend_blob[key].custom_dns_configs[0].fqdn, val.primary_blob_host)
        private_ip_address = try(azurerm_private_endpoint.backend_blob[key].private_service_connection[0].private_ip_address, "")
        subresource_names  = try(azurerm_private_endpoint.backend_blob[key].private_service_connection[0].subresource_names, ["blob"])
        subnet_id          = azurerm_private_endpoint.backend_blob[key].subnet_id
      }
      ecp_level            = key
      tf_backend_container = azapi_resource.tfstate_container[key].name

    }
  }
}

