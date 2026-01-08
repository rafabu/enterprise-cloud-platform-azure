resource "azapi_resource" "resource_group_vwan" {
  type      = "Microsoft.Resources/resourceGroups@2025-04-01"
  name      = "${data.azurecaf_name.rg.result}-vwan-${var.azure_location}"
  parent_id = "/subscriptions/${var.ecp_connectivity_subscription_id}"
  location  = var.azure_location

  tags = var.azure_tags
}

# resource groups for hubs in other regions
resource "azapi_resource" "resource_group_vwan_hub" {
  for_each = toset(distinct([
    for virtual_hub_key, virtual_hub_value in var.virtual_wan_hubs : virtual_hub_value.location
    if virtual_hub_value.location != var.azure_location
  ]))

  type      = "Microsoft.Resources/resourceGroups@2025-04-01"
  name      = "${data.azurecaf_name.rg.result}-vwan-${each.key}"
  parent_id = "/subscriptions/${var.ecp_connectivity_subscription_id}"
  location  = each.key

  tags = var.azure_tags
}

