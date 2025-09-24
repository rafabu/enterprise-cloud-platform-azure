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