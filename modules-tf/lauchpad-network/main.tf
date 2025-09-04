data "azurecaf_name" "rg" {
  name          = "lp"
  resource_type = "azurerm_resource_group"
  prefixes      = ["rabu", "d7"]
  suffixes      = ["y", "z"]
  random_length = 5
  clean_input   = true
  use_slug      = true
}

resource "azurerm_resource_group" "lp" {
  provider = azurerm.lauchpad

  name     = data.azurecaf_name.rg.result
  location = var.azure_location

  tags = var.azure_tags
}
