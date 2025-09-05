output "resource_group_id" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.lp.id
}

output "virtual_network_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.lp.id
}