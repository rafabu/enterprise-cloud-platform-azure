output "virtual_network" {
  value = try([
    for key, val in local.parsed_network_artefacts : {
      id             = azurerm_virtual_network.mgm[key].id
      name           = azurerm_virtual_network.mgm[key].name
      resource_group = azurerm_virtual_network.mgm[key].resource_group_name
      location       = azurerm_virtual_network.mgm[key].location
      address_space  = azurerm_virtual_network.mgm[key].address_space
    }
  ][0], null)
}

output "virtual_network_subnets" {
  value = {
    for key, val in azurerm_subnet.mgm : val.name => {
      id                   = val.id,
      name                 = val.name,
      virtual_network_name = val.virtual_network_name
      resource_group_name  = val.resource_group_name
      address_prefixes     = val.address_prefixes
    }
  }
}

output "key_vault" {
  value = length(try(azurerm_key_vault.mgm["this"].id, null)) == 0 ? null : {
    id             = azurerm_key_vault.mgm["this"].id
    name           = azurerm_key_vault.mgm["this"].name
    resource_group = azurerm_key_vault.mgm["this"].resource_group_name
    location       = azurerm_key_vault.mgm["this"].location
  }
}
