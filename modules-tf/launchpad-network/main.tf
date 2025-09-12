resource "azurerm_resource_group" "lp" {
  provider = azurerm.launchpad

  name     = data.azurecaf_name.rg.result
  location = var.azure_location

  tags = var.azure_tags
}
