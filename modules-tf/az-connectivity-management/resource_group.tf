resource "azapi_resource" "resource_group_mgm" {
  type      = "Microsoft.Resources/resourceGroups@2025-04-01"
  name      = "${data.azurecaf_name.rg.result}"
  parent_id = "/subscriptions/${var.ecp_connectivity_subscription_id}"
  location  = var.azure_location

  tags = var.azure_tags
}
