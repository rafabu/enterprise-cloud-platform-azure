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

data "azuredevops_projects" "projects" {
}

locals {
  azure_devops_project = try([for p in data.azuredevops_projects.projects.projects : p if p.name == var.ecp_azure_devops_project_name][0], {
    project_id  = "00000000-0000-0000-0000-000000000000"
    name        = "mock-project"
    project_url = "https://dev.azure.com/mock-org/_apis/projects/00000000-0000-0000-0000-000000000000"
  })
}

resource "azurerm_resource_group" "mpool" {
  provider = azurerm.launchpad

  name     = data.azurecaf_name.rg.result
  location = var.azure_location

  tags = var.azure_tags
}
