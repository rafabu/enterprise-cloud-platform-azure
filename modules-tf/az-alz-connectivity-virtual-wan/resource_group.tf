resource "azapi_resource" "resource_group_vwan" {
  type      = "Microsoft.Resources/resourceGroups@2025-04-01"
  name      = "${data.azurecaf_name.rg.result}-wan-${lower(local.location_code[local.hub_locations["main"].azure_location])}"
  parent_id = "/subscriptions/${var.ecp_connectivity_subscription_id}"
  location  = local.hub_locations["main"].azure_location

  tags = var.azure_tags
}

# resource groups for hubs in other regions
resource "azapi_resource" "resource_group_vwan_hub" {
  for_each = toset(distinct([
    for k, v in local.virtual_wan_hub_location_map : v.location
    if coalesce(var.azure_location, local.hub_locations["main"].azure_location) != v.location
  ]))

  type      = "Microsoft.Resources/resourceGroups@2025-04-01"
  name      = "${data.azurecaf_name.rg.result}-wan-${lower(local.location_code[each.key])}"
  parent_id = "/subscriptions/${var.ecp_connectivity_subscription_id}"
  location  = each.key

  tags = var.azure_tags
}

