# placeholder to make sure azurerm loads (and does it's job of registering providers)
data "azurerm_client_config" "lp" {
  provider = azurerm.launchpad
}

moved {
  from = azurerm_resource_group.lp
  to   = azapi_resource.lp_rg
}

# resource "azurerm_resource_group" "lp" {
#   provider = azurerm.launchpad

#   name     = data.azurecaf_name.rg.result
#   location = var.azure_location

#   tags = var.azure_tags
# }

resource "azapi_resource" "lp_rg" {
  type      = "Microsoft.Resources/resourceGroups@2025-04-01"
  name      = data.azurecaf_name.rg.result
  parent_id = "/subscriptions/${var.ecp_launchpad_subscription_id}"
  location  = var.azure_location

  tags = var.azure_tags
}
