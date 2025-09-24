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

data "azuread_client_config" "this" {}

data "azuread_directory_object" "this" {
  object_id = data.azuread_client_config.this.object_id
}

data "azuread_users" "this" {
  object_ids = data.azuread_directory_object.this.type == "User" ? [data.azuread_directory_object.this.object_id] : []
}

data "azuread_service_principals" "this" {
  object_ids = data.azuread_directory_object.this.type == "ServicePrincipal" ? [data.azuread_directory_object.this.object_id] : []
}
