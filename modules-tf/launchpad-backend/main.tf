locals {
  launchpad_levels = [
    "l0", # bootstrap
    "l1",
    "l2",
  ]
}

data "azapi_client_config" "this" {
}

data "azurerm_client_config" "this" {
  provider = azurerm.launchpad
}

resource "azurerm_resource_group" "lp" {
  provider = azurerm.launchpad

  for_each = toset(local.launchpad_levels)

  name     = "${data.azurecaf_name.rg.result}-${each.key}"
  location = var.azure_location

  tags = var.azure_tags
}
