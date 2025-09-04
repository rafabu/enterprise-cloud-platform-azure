resource "azurerm_virtual_network" "lp" {
  name                = data.azurecaf_name.lp.results[1]
  location            = azurerm_resource_group.lp.location
  resource_group_name = azurerm_resource_group.lp.name

  address_space = [
    var.virtual_network_address_space
  ]
  encryption {
    enforcement = AllowUnencrypted
  }
  private_endpoint_vnet_policies = "Disabled"

  tags = var.azure_tags
}
