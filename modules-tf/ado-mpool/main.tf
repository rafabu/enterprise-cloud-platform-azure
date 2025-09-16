data "azapi_client_config" "this" {
}

data "azuredevops_client_config" "this" {}

data "azurerm_client_config" "this" {
  provider = azurerm.launchpad
}

data "azurerm_subscription" "launchpad" {
  provider = azurerm.launchpad

  subscription_id = data.azurerm_client_config.this.subscription_id
}

data "azurerm_management_group" "ecp_root_parent" {
  provider = azurerm.launchpad

  name = var.ecp_azure_root_parent_management_group_id
}

data "azuredevops_project" "ecp" {
  name = var.ecp_azure_devops_project_name
}

resource "azurerm_resource_group" "mpool" {
  provider = azurerm.launchpad

  name     = data.azurecaf_name.rg.result
  location = var.azure_location

  tags = var.azure_tags
}
