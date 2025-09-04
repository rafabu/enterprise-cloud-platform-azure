data "azurecaf_name" "lp" {
  name = "lp"
  resource_types = toset([
    "azurerm_resource_group",
    "azurerm_virtual_network"
  ])
  prefixes      = ["rabu", "d7"]
  suffixes      = ["y", "z"]
  random_length = 5
  clean_input   = true
  use_slug      = true
}

resource "azurerm_resource_group" "lp-p" {
  name     = data.azurecaf_name.lp.results[0]
  location = var.azure_location
  
  tags     = var.azure_tags
}