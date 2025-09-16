output "resource_group" {
  description = "Terraform backend resource group created for each ECP deployment level"
  value = {
    id       = azurerm_resource_group.backend.id
    name     = azurerm_resource_group.backend.name
    location = azurerm_resource_group.backend.location
  }
}
