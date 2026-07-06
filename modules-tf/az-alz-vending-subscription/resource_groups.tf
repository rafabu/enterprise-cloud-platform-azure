# Azure Resource Group - Main
# Purpose: pre-provisioned resource group for customer created resources
# resource "azapi_resource" "resource_group_main" {
#   type      = "Microsoft.Resources/resourceGroups@2025-04-01"
#   name      = data.azurecaf_name.rg.result
#   parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
#   location  = var.azure_location

#   body = {
#     properties = {}
#   }

#   tags = var.azure_tags

#   response_export_values = [
#     "id",
#     "name",
#     "location",
#   ]
# }

# Azure Resource Group - Management
# Purpose: Hosting of Azure KeyVault and default Storage Account
resource "azapi_resource" "resource_group_management" {
  type      = "Microsoft.Resources/resourceGroups@2025-04-01"
  name      = "${data.azurecaf_name.rg.result}-mgmt"
  parent_id = module.vending.resource_id
  location  = var.azure_location

  body = {
    properties = {}
  }

  tags = var.azure_tags

  response_export_values = [
    "id",
    "name",
    "location",
  ]

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}


# Azure Resource Group - vNet
# Purpose: the default network configuration
resource "azapi_resource" "resource_group_vnet" {
  type      = "Microsoft.Resources/resourceGroups@2025-04-01"
  name      = "${data.azurecaf_name.rg.result}-vnet"
  parent_id = module.vending.resource_id
  location  = var.azure_location

  body = {
    properties = {}
  }

  tags = var.azure_tags

  response_export_values = [
    "id",
    "name",
    "location",
  ]

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
