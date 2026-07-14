output "resource_group_id" {
  value       = azapi_resource.resource_group.id
  description = "The ID of the resource group."
}

output "virtual_networks" {
  value = {
    for key, val in azapi_resource.bast_vnet : key => {
      id             = val.id
      name           = val.name
      resource_group = azapi_resource.resource_group.name
      location       = val.location
      address_space  = val.body.properties.addressSpace.addressPrefixes
    }
  }
}

output "virtual_network_subnets" {
  value = {
    for key, val in azapi_resource.bast_subnet : val.name => {
      id                   = val.id
      name                 = val.name
      virtual_network_name = provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks", val.parent_id).name
      resource_group_name  = azapi_resource.resource_group.name
      address_prefixes     = [val.body.properties.addressPrefix]
    }
  }
}
