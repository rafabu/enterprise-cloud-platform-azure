data "azurerm_client_config" "this" {
  provider = azurerm.launchpad
}

data "azurerm_subscription" "this" {
  provider = azurerm.launchpad
}

data "azuread_client_config" "this" {}

data "azuread_directory_object" "this" {
  object_id = data.azuread_client_config.this.object_id
}
