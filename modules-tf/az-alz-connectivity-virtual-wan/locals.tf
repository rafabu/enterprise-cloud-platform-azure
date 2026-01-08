
locals {
  virtual_wan_hubs = {
    for virtual_hub_key, virtual_hub_value in var.virtual_wan_hubs : virtual_hub_key => {
      location = lower(coalesce(virtual_hub_value.location, var.azure_location))
      # generated based on location
      resource_group_id = "${provider::azapi::subscription_resource_id(
        var.ecp_connectivity_subscription_id,
        "Microsoft.Resources/resourceGroups",
        [
          "${data.azurecaf_name.rg.result}-vwan-${lower(coalesce(virtual_hub_value.location, var.azure_location))}"
        ]
      )}"

      # computed based on library artefact of virtualNetwork
      address_prefix = distinct(concat(
        var.virtual_network_definitions[virtual_hub_value.address_prefix_artefact_name].addressSpace.addressPrefixes != null ? var.virtual_network_definitions[virtual_hub_value.address_prefix_artefact_name].addressSpace.addressPrefixes : [],
        var.virtual_network_definitions[virtual_hub_value.address_prefix_artefact_name].addressSpace.baseAddressOffsets != null ? [
          for bao in var.virtual_network_definitions[virtual_hub_value.address_prefix_artefact_name].addressSpace.baseAddressOffsets : cidrsubnet(var.ecp_network_main_ipv4_address_space, bao.newbits, bao.netnum)
        ] : []
      ))[0]

      sku                                    = virtual_hub_value.sku
      hub_routing_preference                 = virtual_hub_value.hub_routing_preference
      virtual_router_auto_scale_min_capacity = virtual_hub_value.virtual_router_auto_scale_min_capacity
      tags                                   = coalesce(virtual_hub_value.tags, var.azure_tags, {})
    }
  }
}
