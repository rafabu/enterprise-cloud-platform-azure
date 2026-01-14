
locals {
  virtual_wan_hubs = {
    # normalize key as "ecpa_location" if key begins with "ecpa-"
    for virtual_hub_key, virtual_hub_value in var.virtual_wan_hubs : startswith(virtual_hub_key, "ecpa-") ? "ecpa_${lower(coalesce(virtual_hub_value.location, var.azure_location))}" : virtual_hub_key => {

      enabled_resources = virtual_hub_value.enabled_resources

      location = lower(coalesce(virtual_hub_value.location, var.azure_location))
      # generated based on location
      resource_group_id = "${provider::azapi::subscription_resource_id(
        var.ecp_connectivity_subscription_id,
        "Microsoft.Resources/resourceGroups",
        [
          "${data.azurecaf_name.rg.result}-vwan-${lower(coalesce(virtual_hub_value.location, var.azure_location))}"
        ]
      )}"

      # computed based on library artefact of type virtualNetwork
      address_prefix = distinct(concat(
        var.virtual_network_definitions[virtual_hub_value.address_prefix_artefact_name].addressSpace.addressPrefixes != null ? var.virtual_network_definitions[virtual_hub_value.address_prefix_artefact_name].addressSpace.addressPrefixes : [],
        var.virtual_network_definitions[virtual_hub_value.address_prefix_artefact_name].addressSpace.baseAddressOffsets != null ? [
          for bao in var.virtual_network_definitions[virtual_hub_value.address_prefix_artefact_name].addressSpace.baseAddressOffsets : cidrsubnet(var.ecp_network_main_ipv4_address_space, bao.newbits, bao.netnum)
        ] : []
      ))[0]

      sku                                    = virtual_hub_value.sku
      hub_routing_preference                 = virtual_hub_value.hub_routing_preference
      virtual_router_auto_scale_min_capacity = virtual_hub_value.virtual_router_auto_scale_min_capacity

      virtual_network_connections = {
        for vnc_key, vnc_value in virtual_hub_value.virtual_network_connections : vnc_key => merge(
          {
            # connection name is simply the destination vnet's name
            name = "vnc-${provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks", vnc_value.remote_virtual_network_id).name}"
          },
          vnc_value
        )
      }

      virtual_network_gateways = virtual_hub_value.virtual_network_gateways

      vpn_sites = {
        for vpn_site_key, vpn_site_value in virtual_hub_value.vpn_sites : vpn_site_key => merge(
          {
            # if name isn't provided, fall back to using the object key
            name = coalesce(vpn_site_value.name, vpn_site_key)
          },
          vpn_site_value
        )
      }

      vpn_site_connections = {
        for vsc_key, vsc_value in virtual_hub_value.vpn_site_connections : vsc_key => merge(
          vsc_value,
          {
            name                = coalesce(vsc_value.name, vsc_key)
            remote_vpn_site_key = "${startswith(virtual_hub_key, "ecpa-") ? "ecpa_${lower(coalesce(virtual_hub_value.location, var.azure_location))}" : virtual_hub_key}-${vsc_value.vpn_site_key}"
            vpn_links = [
              for vl in vsc_value.vpn_links : merge(
                vl,
                {
                  name         = "${virtual_hub_value.vpn_sites[vsc_value.vpn_site_key].links[vl.vpn_site_link_number].name}-connection"
                  vpn_site_key = "${startswith(virtual_hub_key, "ecpa-") ? "ecpa_${lower(coalesce(virtual_hub_value.location, var.azure_location))}" : virtual_hub_key}-${vsc_value.vpn_site_key}"
                }
              )
            ]
          }
        )
      }

      tags = coalesce(virtual_hub_value.tags, var.azure_tags, {})
    }
  }
}
