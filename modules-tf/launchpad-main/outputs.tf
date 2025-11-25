output "resource_group" {
  description = "The ID of the resource group"
  value = {
    id       = azurerm_resource_group.lp.id
    name     = azurerm_resource_group.lp.name
    location = azurerm_resource_group.lp.location
  }
}

output "ecp_environment_name" {
  description = "Name of the ECP environment (used for naming resources)"
  value = var.ecp_environment_name
}
