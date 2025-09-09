data "azuredevops_client_config" "this" {}

data "azurerm_client_config" "this" {
    provider = azurerm.lauchpad
}

resource "azurerm_resource_group" "mpool" {
  provider = azurerm.lauchpad

  name     = data.azurecaf_name.rg.result
  location = var.azure_location

  tags = var.azure_tags
}
