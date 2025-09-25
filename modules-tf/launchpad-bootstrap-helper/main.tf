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

###### Simulated (future) backend infrastructure ######
data "azurerm_resources" "backend_storage_accounts" {
  for_each = toset(local.backend_levels)

  provider = azurerm.launchpad

  type = "Microsoft.Storage/storageAccounts"

  resource_group_name = data.azurecaf_name.rg.result
  name                = format("%s%s", data.azurecaf_name.st.result, each.key)
}


###### IP Adress Information ######
data "http" "this_public_ip" {
  url = "https://api.ipify.org?format=json"
}

data "external" "this_local_ip" {
  program = ["pwsh",
    "-File",
    "${path.module}/Get-LocalIPAddress.ps1"
  ]

  query = null
}
