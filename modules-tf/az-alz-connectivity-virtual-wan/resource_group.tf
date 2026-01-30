resource "azapi_resource" "resource_group_vwan" {
  type      = "Microsoft.Resources/resourceGroups@2025-04-01"
  name      = "${data.azurecaf_name.rg.result}-wan-${lower(local.location_code[var.azure_location])}"
  parent_id = "/subscriptions/${var.ecp_connectivity_subscription_id}"
  location  = var.azure_location

  tags = var.azure_tags
}

# resource groups for hubs in other regions
resource "azapi_resource" "resource_group_vwan_hub" {
  for_each = toset(distinct([
    for virtual_hub_key, virtual_wan_hub_locations in local.virtual_wan_hub_locations : virtual_wan_hub_locations.location
    if coalesce(virtual_wan_hub_locations.location, var.azure_location) != var.azure_location
  ]))

  type      = "Microsoft.Resources/resourceGroups@2025-04-01"
  name      = "${data.azurecaf_name.rg.result}-wan-${lower(local.location_code[each.key])}"
  parent_id = "/subscriptions/${var.ecp_connectivity_subscription_id}"
  location  = each.key

  tags = var.azure_tags
}

