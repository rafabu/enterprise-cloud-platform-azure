resource "azapi_resource" "resource_group_vnet" {
  type      = "Microsoft.Resources/resourceGroups@2025-04-01"
  name      = "${data.azurecaf_name.rg.result}-vnet-${lower(local.location_code[local.hub_locations["main"].azure_location])}"
  parent_id = "/subscriptions/${var.ecp_connectivity_subscription_id}"
  location  = local.hub_locations["main"].azure_location

  tags = var.azure_tags
}
