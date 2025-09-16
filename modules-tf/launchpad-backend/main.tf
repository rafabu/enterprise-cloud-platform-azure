locals {
  backend_levels = [
    "l0", # bootstrap
    "l1",
    "l2",
  ]
}

data "azurerm_client_config" "this" {
  provider = azurerm.launchpad
}

resource "azurerm_resource_group" "backend" {
  provider = azurerm.launchpad

  name     = data.azurecaf_name.rg.result
  location = var.azure_location

  tags = var.azure_tags
}
