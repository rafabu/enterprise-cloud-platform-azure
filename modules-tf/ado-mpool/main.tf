data "azuredevops_client_config" "this" {}

data "azurerm_client_config" "this" {
  provider = azurerm.lauchpad
}

data "azurerm_management_group" "ecp_root_parent" {
  provider = azurerm.lauchpad

  name = var.ecp_azure_root_parent_management_group_id
}

resource "azurerm_resource_group" "mpool" {
  provider = azurerm.lauchpad

  name     = data.azurecaf_name.rg.result
  location = var.azure_location

  tags = var.azure_tags
}
