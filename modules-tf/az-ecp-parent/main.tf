data "azurerm_client_config" "this" {
  provider = azurerm.launchpad
}

data "azuread_directory_object" "this" {
  object_id = data.azurerm_client_config.this.object_id
}

