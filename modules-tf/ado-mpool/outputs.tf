output "resource_group" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.mpool.id
}

output "virtual_network_subnets" {
  description = "core properties of virtual networks subnets"
  value = {
    for key, val in azurerm_subnet.mpool : key => {
      id                   = val.id,
      name                 = val.name,
      virtual_network_name = val.virtual_network_name
      resource_group_name  = val.resource_group_name
      address_prefixes     = val.address_prefixes
    }
  }
}
