resource "azurerm_virtual_network" "lp" {
  provider = azurerm.lauchpad

  for_each = toset(var.virtual_network_artefact_names)

  name                = data.azurecaf_name.vnet[each.key].result
  location            = azurerm_resource_group.lp.location
  resource_group_name = azurerm_resource_group.lp.name

  address_space = [
    var.virtual_network_definitions[each.key].addressSpace.addressPrefixes[0]
  ]
  encryption {
    enforcement = "AllowUnencrypted"
  }
  private_endpoint_vnet_policies = "Disabled"

  tags = var.azure_tags
}
