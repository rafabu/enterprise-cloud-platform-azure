data "azurecaf_name" "vnet" {
  name          = "lp"
  resource_type = "azurerm_virtual_network"
  prefixes      = ["rabu", "d7"]
  suffixes      = ["y", "z"]
  random_length = 5
  clean_input   = true
  use_slug      = true
}

resource "azurerm_virtual_network" "lp" {
  name                = data.azurecaf_name.vnet.result
  location            = azurerm_resource_group.lp.location
  resource_group_name = azurerm_resource_group.lp.name

  address_space = [
    var.virtual_network_address_space
  ]
  encryption {
    enforcement = "AllowUnencrypted"
  }
  private_endpoint_vnet_policies = "Disabled"

  tags = var.azure_tags
}
