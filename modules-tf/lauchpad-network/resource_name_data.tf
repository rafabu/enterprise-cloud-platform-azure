data "azurecaf_name" "rg" {
  name          = "ecpalp"
  resource_type = "azurerm_resource_group"
  prefixes      = ["rabu", "d7"]
  suffixes      = ["main"]
  random_length = 0
  clean_input   = true
  use_slug      = true
}

data "azurecaf_name" "vnet" {
  name          = "ecpalp"
  resource_type = "azurerm_virtual_network"
  prefixes      = ["rabu", "d7"]
  suffixes      = ["main"]
  random_length = 0
  clean_input   = true
  use_slug      = true
}
