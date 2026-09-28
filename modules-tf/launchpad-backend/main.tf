locals {
  backend_levels = [
    "l0", # bootstrap
    "l1",
    "l2",
    "l3",
  ]
}

data "azurerm_client_config" "this" {
  provider = azurerm.launchpad
}

resource "azapi_resource" "launchpad_rg" {
  type      = "Microsoft.Resources/resourceGroups@2025-04-01"
  name      = data.azurecaf_name.launchpad_rg.result
  parent_id = "/subscriptions/${var.ecp_launchpad_subscription_id}"
  location  = var.azure_location

  tags = var.azure_tags
}

moved {
  from = azurerm_resource_group.backend
  to   = azapi_resource.backend_rg
}


resource "azapi_resource" "backend_rg" {
  type      = "Microsoft.Resources/resourceGroups@2025-04-01"
  name      = data.azurecaf_name.backend_rg.result
  parent_id = "/subscriptions/${var.ecp_launchpad_subscription_id}"
  location  = var.azure_location

  tags = var.azure_tags
}
