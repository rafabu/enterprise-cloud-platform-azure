locals {

  # ECP ARTEFACT DEFAULTS
  network_artefact_default  = "l2-connectivity-vwan-hub"
  vwan_hub_artefact_default = "l2-connectivity-default-vwan-hub"

  # ECP replacement match pattern
  matchpattern_ecp_artefact  = "(?i)^<ECP_ARTEFACT>:(.+)$"
  matchpattern_ecp_parameter = "(?i)^<ECP_PARAMETER>:(.+)$"

  # Step 1: Parse all artefact files once
  parsed_hub_artefacts = {
    for k, v in var.virtual_hub_artefacts : k => jsondecode(file(v.filePath))
  }
  parsed_network_artefacts = {
    for k, v in var.virtual_network_artefacts : k => jsondecode(file(v.filePath))
  }
  parsed_vpn_gateway_artefacts = {
    for k, v in var.vpn_gateway_artefacts : k => jsondecode(file(v.filePath))
  }

  parsed_vpn_site_artefacts = {
    for k, v in var.vpn_site_artefacts : k => jsondecode(file(v.filePath))
  }

  # Step 2: Extract address prefix info from each hub artefact
  virtual_hub_address_info = {
    for hub_key, parsed_hub in local.parsed_hub_artefacts : hub_key => {
      raw_address_prefix = parsed_hub.addressPrefix
      is_artefact_ref    = can(regex(local.matchpattern_ecp_artefact, parsed_hub.addressPrefix))
    }
  }

  # Step 3: Determine which network artefact to use for each hub
  virtual_hub_network_artefact = {
    for hub_key, addr_info in local.virtual_hub_address_info : hub_key => {
      artefact_name = addr_info.is_artefact_ref ? regex(local.matchpattern_ecp_artefact, addr_info.raw_address_prefix)[0] : local.network_artefact_default
    }
  }

  # Step 4: Resolve the final address prefix for each hub
  virtual_hub_address_prefix = {
    for hub_key, addr_info in local.virtual_hub_address_info : hub_key => {
      address_prefix = !addr_info.is_artefact_ref ? addr_info.raw_address_prefix : (
        distinct(concat(
          try(local.parsed_network_artefacts[local.virtual_hub_network_artefact[hub_key].artefact_name].addressSpace.addressPrefixes, []),
          try([
            for offset in local.parsed_network_artefacts[local.virtual_hub_network_artefact[hub_key].artefact_name].addressSpace.baseAddressOffsets :
            cidrsubnet(var.ecp_network_main_ipv4_address_space, offset.newbits, offset.netnum)
          ], [])
        ))[0]
      )
    }
  }

  # Step 5: Extract location from each hub artefact
  virtual_wan_hub_locations = {
    for hub_key, parsed_hub in local.parsed_hub_artefacts : hub_key => {
      location = coalesce(
        try(
          lower(parsed_hub.location) == "default" ? null : parsed_hub.location,
          null
        ),
        var.azure_location
      )
    }
  }

  ### VPN Gateway Artefact Processing ###
  vpn_gateway_vhub_info = {
    for k, v in local.parsed_vpn_gateway_artefacts : k => {
      raw_hub_id      = v.virtualHub.id
      is_artefact_ref = can(regex(local.matchpattern_ecp_artefact, v.virtualHub.id))
    }
  }

  vpn_gateway_vhub_artefact = {
    for k, v in local.vpn_gateway_vhub_info : k => {
      artefact_name = v.is_artefact_ref ? regex(local.matchpattern_ecp_artefact, v.raw_hub_id)[0] : local.vwan_hub_artefact_default
    }
  }

  vpn_gateway_location_info = {
    for k, v in local.parsed_vpn_gateway_artefacts : k => {
      location = coalesce(
        try(
          lower(v.location) == "default" ? null : v.location,
          null
        ),
        var.azure_location
      )
    }
  }

  vpn_gateway_objects_hub_resolved = {
    for k, v in var.virtual_hub_artefacts : k => {
      # not a map despite the plural - needs a single object per hub
      virtual_network_gateways = try([
        for gw_k, gw_v in local.parsed_vpn_gateway_artefacts : {
          # artefactName = gw_k
          subnet_address_prefix                     = null
          subnet_default_outbound_access_enabled    = null
          route_table_creation_enabled              = null
          route_table_name                          = null
          route_table_bgp_route_propagation_enabled = null

          vpn = {
            bgp_route_translation_for_nat_enabled = try(gw_v.enableBgpRouteTranslationForNat, false)
            bgp_settings = {
              instance_0_bgp_peering_address = try([
                for bgp_pa in try(gw_v.bgpSettings.bgpPeeringAddresses, []) : {
                  custom_ips = try(bgp_pa.customBgpIpAddresses, [])
                }
                if try(bgp_pa.ipconfigurationId, "") == "Instance0"
              ][0], { custom_ips = [] })
              instance_1_bgp_peering_address = try([
                for bgp_pa in try(gw_v.bgpSettings.bgpPeeringAddresses, []) : {
                  custom_ips = try(bgp_pa.customBgpIpAddresses, [])
                }
                if try(bgp_pa.ipconfigurationId, "") == "Instance1"
              ][0], { custom_ips = [] })
              peer_weight = coalesce(try(gw_v.bgpSettings.peerWeight, null), 0)
              asn         = coalesce(try(gw_v.bgpSettings.asn, null), 65515)
            }
            routing_preference = try(gw_v.isRoutingPreferenceInternet, false) ? "Internet" : "Microsoft Network"
            scale_unit         = coalesce(try(gw_v.vpnGatewayScaleUnit, null), 1)
          }
        }
        # add only when hub artefact && location matches
        if try(local.vpn_gateway_vhub_artefact[gw_k].artefact_name, "") == k &&
        try(local.vpn_gateway_location_info[gw_k].location, "") == local.virtual_wan_hub_locations[k].location
      ][0], null)
    }
  }

  ### VPN Remote Site Artefact Processing ###
  vpn_site_location_info = {
    for k, v in local.parsed_vpn_site_artefacts : k => {
      location = coalesce(
        try(
          lower(v.location) == "default" ? null : v.location,
          null
        ),
        var.azure_location
      )
    }
  }

  vpn_site_objects_hub_resolved = {
    for k, v in var.virtual_hub_artefacts : k => {
      vpn_sites = try({
        for s_k, s_v in local.parsed_vpn_site_artefacts : s_k => {
          name = coalesce(try(s_v.name, null), s_k)
          links = [
            for link in s_v.vpnSiteLinks :
            {
              name = try(link.name, "link${index(s_v.vpnSiteLinks, link) + 1}")
              bgp = {
                asn             = try(link.properties.bgpProperties.asn, null)
                peering_address = try(link.properties.bgpProperties.bgpPeeringAddress, null)
              }
              fqdn          = try(link.properties.fqdn, null)
              ip_address    = try(link.properties.ipAddress, null)
              provider_name = try(link.properties.linkProperties.linkProviderName, null)
              speed_in_mbps = try(link.properties.linkProperties.linkSpeedInMbps, 0)

            }
          ]
          address_cidrs = try(s_v.addressSpace.addressPrefixes, [])
          device_model  = try(s_v.deviceProperties.deviceModel, null)
          device_vendor = try(s_v.deviceProperties.deviceVendor, null)
          o365_policy = {
            traffic_category = {
              allow_endpoint_enabled    = try(s_v.o365Policy.breakOutCategories.allow, false)
              default_endpoint_enabled  = try(s_v.o365Policy.breakOutCategories.default, false)
              optimize_endpoint_enabled = try(s_v.o365Policy.breakOutCategories.optimize, false)
            }
          }
        }
        # add only when location matches hub
        if try(local.vpn_site_location_info[s_k].location, "") == local.virtual_wan_hub_locations[k].location
      }, null)
    }
  }



  ### vWAN Hub definition for AVN moddule ###

  virtual_wan_hubs = {
    # normalize key as "ecpa_location" if artefact is "l2-connectivity-default-vwan-hub" (the default)
    for virtual_hub_key, virtual_hub_value in var.virtual_hub_artefacts : virtual_hub_key == local.vwan_hub_artefact_default ? "ecpa_${lower(local.virtual_wan_hub_locations[virtual_hub_key].location)}" : virtual_hub_key => {

      enabled_resources = {
        firewall                              = false
        firewall_policy                       = false
        bastion                               = false
        virtual_network_gateway_express_route = false
        # vpn gateway only when active artefacts are loaded
        virtual_network_gateway_vpn = try(length(local.vpn_gateway_objects_hub_resolved[virtual_hub_key].virtual_network_gateways), 0)  > 0
        private_dns_zones           = false
        private_dns_resolver        = false
        sidecar_virtual_network     = false
      }

      # if location is not present or "default", use var.azure_location
      location = lower(local.virtual_wan_hub_locations[virtual_hub_key].location)

      # generated based on location
      resource_group_id = "${provider::azapi::subscription_resource_id(
        var.ecp_connectivity_subscription_id,
        "Microsoft.Resources/resourceGroups",
        [
          "${data.azurecaf_name.rg.result}-vwan-${lower(local.virtual_wan_hub_locations[virtual_hub_key].location)}"
        ]
      )}"

      # computed based on library artefact of type virtualNetwork
      address_prefix = local.virtual_hub_address_prefix[virtual_hub_key].address_prefix

      sku                                    = try(local.parsed_hub_artefacts[virtual_hub_key].sku, "Basic")
      hub_routing_preference                 = try(local.parsed_hub_artefacts[virtual_hub_key].hubRoutingPreference, "ExpressRoute")
      virtual_router_auto_scale_min_capacity = try(local.parsed_hub_artefacts[virtual_hub_key].virtualRouterAutoScaleConfiguration.minCapacity, 2)

      virtual_network_connections = {
        for vnc_key, vnc_value in var.virtual_wan_hubs["ecpa-default-location"].virtual_network_connections : vnc_key => merge(
          {
            # connection name is simply the destination vnet's name
            name = "vnc-${provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks", vnc_value.remote_virtual_network_id).name}"
          },
          vnc_value
        )
      }

      virtual_network_gateways = try(local.vpn_gateway_objects_hub_resolved[virtual_hub_key].virtual_network_gateways, {})

      vpn_sites = try(local.vpn_site_objects_hub_resolved[virtual_hub_key].vpn_sites, {})


      vpn_site_connections = {}
      # vpn_site_connections = {
      #   for vsc_key, vsc_value in var.virtual_wan_hubs["ecpa-default-location"].vpn_site_connections : vsc_key => merge(
      #     vsc_value,
      #     {
      #       name                = coalesce(vsc_value.name, vsc_key)
      #       remote_vpn_site_key = "${ virtual_hub_key == "vwan_hub_artefact_default" ? "ecpa_${lower(coalesce(virtual_hub_value.location, var.azure_location))}" : virtual_hub_key}-${vsc_value.vpn_site_key}"
      #       vpn_links = [
      #         for vl in vsc_value.vpn_links : merge(
      #           vl,
      #           {
      #             name         = "${virtual_hub_value.vpn_sites[vsc_value.vpn_site_key].links[vl.vpn_site_link_number].name}-connection"
      #             vpn_site_key = "${ virtual_hub_key == "vwan_hub_artefact_default" ? "ecpa_${lower(coalesce(virtual_hub_value.location, var.azure_location))}" : virtual_hub_key}-${vsc_value.vpn_site_key}"
      #           }
      #         )
      #       ]
      #     }
      #   )
      # }

      tags = var.azure_tags
    }
  }
}
