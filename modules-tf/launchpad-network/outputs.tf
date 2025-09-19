output "virtual_networks" {
  description = "core properties of virtual networks created"
  value = {
    for key, val in azurerm_virtual_network.lp : key => {
      id                  = val.id,
      name                = val.name,
      location            = val.location
      resource_group_name = val.resource_group_name
      address_space       = val.address_space
    }
  }
}

output "virtual_network_subnets" {
  description = "core properties of virtual networks subnets"
  value = {
    for key, val in azurerm_subnet.lp : key => {
      id                   = val.id,
      name                 = val.name,
      virtual_network_name = val.virtual_network_name
      resource_group_name  = val.resource_group_name
      address_prefixes     = val.address_prefixes
    }
  }
}
