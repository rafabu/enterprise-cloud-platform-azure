locals {
  location_code = {
    for k, v in module.azure-region-info.regions_by_name : k => coalesce(v.geo_code, v.short_name)
  }

  hub_locations = merge(
    var.azure_location != "" && var.ecp_network_main_ipv4_address_space != "" ? {
      "main" = {
        azure_location                      = var.azure_location
        ecp_network_main_ipv4_address_space = var.ecp_network_main_ipv4_address_space
        is_main_location                    = true
      }
      } : {
      for k, v in var.ecp_hub_locations : "main" => {
        azure_location                      = v.azure_location
        ecp_network_main_ipv4_address_space = v.ecp_network_main_ipv4_address_space
        is_main_location                    = coalesce(v.is_main_location, false)
      }
      if coalesce(v.is_main_location, false) == true
    },
    {
      for k, v in var.ecp_hub_locations : k => {
        azure_location                      = v.azure_location
        ecp_network_main_ipv4_address_space = v.ecp_network_main_ipv4_address_space
        is_main_location                    = coalesce(v.is_main_location, false)
      }
      if coalesce(v.is_main_location, false) == false
    }
  )

  # ECP ARTEFACT DEFAULTS
  network_artefact_default  = "l2-connectivity-vwan-hub"
  vwan_hub_artefact_default = "l2-connectivity-default-vwan-hub"

  # ECP replacement match pattern
  matchpattern_ecp_artefact  = "(?i)^<ECP_ARTEFACT>:(.+)$"
  matchpattern_ecp_parameter = "(?i)^<ECP_PARAMETER>:(.+)$"

  # Parse all artefact files once
  #    and filter by definition list where needed
  parsed_wan_artefacts = {
    for k, v in var.virtual_wan_artefacts : k => jsondecode(file(v.filePath))
    if contains(var.ecp_archetype_definitions.virtual_wan, k)
  }

  parsed_hub_artefacts = {
    for k, v in var.virtual_hub_artefacts : k => jsondecode(file(v.filePath))
    if contains(var.ecp_archetype_definitions.virtual_hub, k)
  }

  parsed_network_artefacts = {
    for k, v in var.virtual_network_artefacts : k => jsondecode(file(v.filePath))
    # we need all here, as the wan hub artefact contains the filter statement
  }

  parsed_vpn_gateway_artefacts = {
    for k, v in var.vpn_gateway_artefacts : k => jsondecode(file(v.filePath))
    if contains(var.ecp_archetype_definitions.vpn_gateway, k)
  }

  parsed_vpn_site_artefacts = {
    for k, v in var.vpn_site_artefacts : k => jsondecode(file(v.filePath))
    if contains(var.ecp_archetype_definitions.vpn_site, k)
  }

  parsed_vpn_connection_artefacts = {
    for k, v in var.vpn_connection_artefacts : k => jsondecode(file(v.filePath))
    if contains(var.ecp_archetype_definitions.vpn_connection, k)
  }

  ### Virtual WAN Artefact Processing ###
  virtual_wan_location_list = [
    for k, v in local.parsed_wan_artefacts : {
      for l_k, l_v in local.hub_locations : "${l_k}_${k}" => {
        location = coalesce(
          try(
            lower(v.location) == "default" ? null : l_v.azure_location,
            null
          ),
          local.hub_locations["main"].azure_location
        )
      }
    }
  ]

  virtual_wan_location_map = zipmap(
    flatten([for entry, attr in local.virtual_wan_location_list : keys(attr)]),
    flatten([for entry, attr in local.virtual_wan_location_list : values(attr)])
  )

  # virtual wan resource is always created in main location only
  virtual_wan_object = try(flatten([
    for k, v in local.parsed_wan_artefacts : [
      for l_k, l_v in local.hub_locations : {
        wan_artefact_key = k
        location_key     = l_k

        # # set name here; otherwise AVM modules decides on (var.virtual_hubs)[0] - which isn't deterministic in our case
        name                              = "${data.azurecaf_name.vwan.result}-${lower(local.location_code[l_v.azure_location])}-01"
        location                          = l_v.azure_location
        resource_group_name               = "${data.azurecaf_name.rg.result}-wan-${lower(local.location_code[l_v.azure_location])}"
        type                              = try(v.type, "Standard")
        allow_branch_to_branch_traffic    = try(v.allowBranchToBranchTraffic, true)
        disable_vpn_encryption            = try(v.disableVpnEncryption, false)
        office365_local_breakout_category = try(v.office365LocalBreakoutCategory, "Optimize")
      }
      if try(l_v.is_main_location, false) == true
    ]
  ])[0], {})

  ### Virtual Hub Artefact Processing ###


  virtual_hub_address_info = {
    for hub_key, parsed_hub in local.parsed_hub_artefacts : hub_key => {
      raw_address_prefix = parsed_hub.addressPrefix
      is_artefact_ref    = can(regex(local.matchpattern_ecp_artefact, parsed_hub.addressPrefix))
    }
  }

  virtual_hub_address_prefix_list = [
    for k, v in local.virtual_hub_address_info : {
      for l_k, l_v in local.hub_locations : "${l_k}_${k}" => {
        address_prefix = !v.is_artefact_ref ? v.raw_address_prefix : (
          distinct(concat(
            try(local.parsed_network_artefacts[local.virtual_hub_network_artefact[k].artefact_name].addressSpace.addressPrefixes, []),
            try([
              for offset in local.parsed_network_artefacts[local.virtual_hub_network_artefact[k].artefact_name].addressSpace.baseAddressOffsets :
              cidrsubnet(l_v.ecp_network_main_ipv4_address_space, offset.newbits, offset.netnum)
            ], [])
          ))[0]
        )
      }
    }
  ]

  virtual_hub_address_prefix_map = zipmap(
    flatten([for entry, attr in local.virtual_hub_address_prefix_list : keys(attr)]),
    flatten([for entry, attr in local.virtual_hub_address_prefix_list : values(attr)])
  )

  virtual_wan_hub_location_list = [
    for k, v in local.parsed_hub_artefacts : {
      for l_k, l_v in local.hub_locations : "${l_k}_${k}" => {
        location = coalesce(
          try(
            # on hubs, 'default' means one per location
            l_v.azure_location,
            null
          ),
          local.hub_locations["main"].azure_location
        )
      }
    }
  ]

  virtual_wan_hub_location_map = zipmap(
    flatten([for entry, attr in local.virtual_wan_hub_location_list : keys(attr)]),
    flatten([for entry, attr in local.virtual_wan_hub_location_list : values(attr)])
  )

  virtual_hub_location_list = [
    for k, v in var.virtual_hub_artefacts : {
      for l_k, l_v in local.hub_locations : "${l_k}_${k}" => {
        location = coalesce(
          try(
            lower(v.location) == "default" ? null : l_v.azure_location,
            null
          ),
          local.hub_locations["main"].azure_location
        )
      }
    }
  ]

  virtual_hub_location_map = zipmap(
    flatten([for entry, attr in local.virtual_hub_location_list : keys(attr)]),
    flatten([for entry, attr in local.virtual_hub_location_list : values(attr)])
  )

  virtual_hub_network_artefact = {
    for hub_key, addr_info in local.virtual_hub_address_info : hub_key => {
      artefact_name = addr_info.is_artefact_ref ? regex(local.matchpattern_ecp_artefact, addr_info.raw_address_prefix)[0] : local.network_artefact_default
    }
  }

  virtual_hub_list = [
    # support several hubs in a single location (different address spaces - add address to key
    for k, v in var.virtual_hub_artefacts : {
      for l_k, l_v in local.hub_locations : k == local.vwan_hub_artefact_default ? "ecpa_${lower(local.virtual_wan_hub_location_map["${l_k}_${k}"].location)}_${local.virtual_hub_address_prefix_map["${l_k}_${k}"].address_prefix}" : "${l_k}_${k}_${local.virtual_hub_address_prefix_map["${l_k}_${k}"].address_prefix}" => {

        hub_artefact_key = k
        location_key     = l_k

        is_primary_region_hub = l_k == "main"

        enabled_resources = {
          firewall                              = false
          firewall_policy                       = false
          bastion                               = false
          virtual_network_gateway_express_route = false
          # vpn gateway only when active artefacts are loaded
          virtual_network_gateway_vpn = try(local.vpn_gateway_objects_hub_resolved_map["${l_k}_${k}"].virtual_network_gateways.gateway_artefact_key, "") != "default" || try(length(local.vpn_connection_objects_hub_resolved_map["${l_k}_${k}"].vpn_site_connections), 0) > 0
          private_dns_zones           = false
          private_dns_resolver        = false
          sidecar_virtual_network     = false
        }

        location = lower(local.virtual_wan_hub_location_map["${l_k}_${k}"].location)

        # generated based on location
        resource_group_id = "${provider::azapi::subscription_resource_id(
          var.ecp_connectivity_subscription_id,
          "Microsoft.Resources/resourceGroups",
          [
            "${data.azurecaf_name.rg.result}-wan-${lower(local.location_code[local.virtual_wan_hub_location_map["${l_k}_${k}"].location])}"
          ]
        )}"

        # computed based on library artefact of type virtualNetwork
        address_prefix = local.virtual_hub_address_prefix_map["${l_k}_${k}"].address_prefix
        sku            = try(local.parsed_hub_artefacts[k].sku, local.virtual_wan_object.type) # SKU should match the one of wan)

        hub_routing_preference                 = try(local.parsed_hub_artefacts[k].hubRoutingPreference, "ExpressRoute")
        virtual_router_auto_scale_min_capacity = try(local.parsed_hub_artefacts[k].virtualRouterAutoScaleConfiguration.minCapacity, 2)

        # vnc are not currently coming from artefact; only via variable input
        virtual_network_connections = {
          for vnc_key, vnc_value in try(var.virtual_wan_hubs[k].virtual_network_connections, {}) : vnc_key => merge(
            {
              # connection name is simply the destination vnet's name
              name = "vnc-${provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks", vnc_value.remote_virtual_network_id).name}"
            },
            vnc_value
          )
          # connect to all matching artefacts || only to the main location  
          if vnc_value.connect_to_main_location == false || (vnc_value.connect_to_main_location == true && l_k == "main")
        }

        # vpn gateways are only required if connections are defined (or a non-default one is defined via artefacts
        virtual_network_gateways = merge(
          try(local.vpn_gateway_objects_hub_resolved_map["${l_k}_${k}"].virtual_network_gateways, {}),
          {
            for vng_key, vng_value in try(var.virtual_wan_hubs[k].virtual_network_gateways, {}) : vng_key => vng_value
          }
        )

        vpn_sites = merge(
          try(local.vpn_site_objects_hub_resolved_map["${l_k}_${k}"].vpn_sites, {}),
          {
            for vns_key, vns_value in try(var.virtual_wan_hubs[k].vpn_sites, {}) : vns_key => vns_value
          }
        )

        vpn_site_connections = merge(
          try(local.vpn_connection_objects_hub_resolved_map["${l_k}_${k}"].vpn_site_connections, {}),
          {
            for vnc_key, vnc_value in try(var.virtual_wan_hubs[k].vpn_site_connections, {}) : vnc_key => vnc_value
          }
        )
        tags = var.azure_tags
      }
    }
  ]

  virtual_hub_map = zipmap(
    flatten([for entry, attr in local.virtual_hub_list : keys(attr)]),
    flatten([for entry, attr in local.virtual_hub_list : values(attr)])
  )

  virtual_hub_location_id_map = {
    for k, v in local.virtual_hub_location_map : k => {
      value = format("%02d", random_integer.virtual_hub_id[k].result)
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

  vpn_gateway_location_list = [
    for k, v in local.parsed_vpn_gateway_artefacts : {
      for l_k, l_v in local.hub_locations : "${l_k}_${k}" => {
        location = coalesce(
          try(
            lower(v.location) == "default" ? null : l_v.azure_location,
            null
          ),
          local.hub_locations["main"].azure_location
        )
      }
    }
  ]

  vpn_gateway_location_map = zipmap(
    flatten([for entry, attr in local.vpn_gateway_location_list : keys(attr)]),
    flatten([for entry, attr in local.vpn_gateway_location_list : values(attr)])
  )

  vpn_gateway_objects_hub_resolved_list = [
    for k, v in var.virtual_hub_artefacts : {
      for l_k, l_v in local.hub_locations : "${l_k}_${k}" => {
        # not a map despite the plural - needs a single object per hub
        virtual_network_gateways = try(
          [
            for gw_k, gw_v in local.parsed_vpn_gateway_artefacts : {
              hub_artefact_key     = k
              gateway_artefact_key = gw_k
              location_key         = l_k

              subnet_address_prefix                     = null
              subnet_default_outbound_access_enabled    = null
              route_table_creation_enabled              = null
              route_table_name                          = null
              route_table_bgp_route_propagation_enabled = null

              vpn = {
                # deterministic naming, following the pattern of wan-hub
                name = k == local.vwan_hub_artefact_default ? "${replace(data.azurecaf_name.vwan.result, "-vwan-", "-vpng-")}-${lower(local.location_code[local.virtual_wan_hub_location_map["${l_k}_${k}"].location])}-01" : "${replace(data.azurecaf_name.vwan.result, "-vwan-", "-vpng-")}-${lower(local.location_code[local.virtual_wan_hub_location_map["${l_k}_${k}"].location])}-${format("%02d", random_integer.virtual_hub_id["${l_k}_${k}"].result)}"

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
            try(local.vpn_gateway_location_map["${l_k}_${gw_k}"].location, "") == local.virtual_wan_hub_location_map["${l_k}_${k}"].location
          ][0],
          # if connections are defined, we need at least a default gateway object for its name
          # otherwise, no deployment is needed
          {
            hub_artefact_key     = k
            gateway_artefact_key = "default"
            location_key         = l_k

            vpn = {
              # deterministic naming, following the pattern of wan-hub
              name = k == local.vwan_hub_artefact_default ? "${replace(data.azurecaf_name.vwan.result, "-vwan-", "-vpng-")}-${lower(local.location_code[local.virtual_wan_hub_location_map["${l_k}_${k}"].location])}-01" : "${replace(data.azurecaf_name.vwan.result, "-vwan-", "-vpng-")}-${lower(local.location_code[local.virtual_wan_hub_location_map["${l_k}_${k}"].location])}-${format("%02d", random_integer.virtual_hub_id["${l_k}_${k}"].result)}"
            }
          }
        )
      }
    }
  ]

  vpn_gateway_objects_hub_resolved_map = zipmap(
    flatten([for entry, attr in local.vpn_gateway_objects_hub_resolved_list : keys(attr)]),
    flatten([for entry, attr in local.vpn_gateway_objects_hub_resolved_list : values(attr)])
  )

  ### VPN Site Artefact Processing ###
  vpn_site_location_list = [
    for k, v in local.parsed_vpn_site_artefacts : {
      for l_k, l_v in local.hub_locations : "${l_k}_${k}" => {
        location = coalesce(
          try(
            lower(v.location) == "default" ? null : l_v.azure_location,
            null
          ),
          local.hub_locations["main"].azure_location
        )
      }
    }
  ]

  vpn_site_location_map = zipmap(
    flatten([for entry, attr in local.vpn_site_location_list : keys(attr)]),
    flatten([for entry, attr in local.vpn_site_location_list : values(attr)])
  )

  vpn_site_objects_hub_resolved_list = [
    for k, v in var.virtual_hub_artefacts : {
      for l_k, l_v in local.hub_locations : "${l_k}_${k}" => {
        # can be multiple vpn sites per hub
        vpn_sites = {
          for s_k, s_v in local.parsed_vpn_site_artefacts : s_k => {
            hub_artefact_key  = k
            site_artefact_key = s_k
            location_key      = l_k

            site_location = local.vpn_site_location_map["${l_k}_${s_k}"].location


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
          if try(local.vpn_site_location_map["${l_k}_${s_k}"].location, "") == local.virtual_wan_hub_location_map["${l_k}_${k}"].location
        }
      }
    }
  ]
  vpn_site_objects_hub_resolved_map = zipmap(
    flatten([for entry, attr in local.vpn_site_objects_hub_resolved_list : keys(attr)]),
    flatten([for entry, attr in local.vpn_site_objects_hub_resolved_list : values(attr)])
  )

  ### VPN Connections Artefact Processing ###

  vpn_connection_dependency_info = {
    for k, v in local.parsed_vpn_connection_artefacts : k => {
      gw_id_raw            = try(v.vpnGateway.id, "")
      gw_is_artefact_ref   = can(regex(local.matchpattern_ecp_artefact, try(v.vpnGateway.id, "")))
      site_id_raw          = v.remoteVpnSite.id
      site_is_artefact_ref = can(regex(local.matchpattern_ecp_artefact, v.remoteVpnSite.id))
    }
  }

  vpn_connection_vhub_artefact = {
    for k, v in local.vpn_connection_dependency_info : k => {
      gw_artefact_name   = v.gw_is_artefact_ref ? regex(local.matchpattern_ecp_artefact, v.gw_id_raw)[0] : ""
      site_artefact_name = v.site_is_artefact_ref ? regex(local.matchpattern_ecp_artefact, v.site_id_raw)[0] : ""
    }
  }

  vpn_connection_location_list = [
    for k, v in local.parsed_vpn_connection_artefacts : {
      for l_k, l_v in local.hub_locations : "${l_k}_${k}" => {
        location = coalesce(
          try(
            lower(v.location) == "default" ? null : l_v.azure_location,
            null
          ),
          local.hub_locations["main"].azure_location
        )
      }
    }
  ]

  vpn_connection_location_map = zipmap(
    flatten([for entry, attr in local.vpn_connection_location_list : keys(attr)]),
    flatten([for entry, attr in local.vpn_connection_location_list : values(attr)])
  )

  vpn_connection_objects_hub_resolved_list = [
    for k, v in var.virtual_hub_artefacts : {
      for l_k, l_v in local.hub_locations : "${l_k}_${k}" => {
        vpn_site_connections = {
          for c_k, c_v in local.parsed_vpn_connection_artefacts : c_k => {
            hub_artefact_key        = k
            connection_artefact_key = c_k
            site_artefact_key       = local.vpn_connection_dependency_info[c_k].site_is_artefact_ref ? local.vpn_connection_vhub_artefact[c_k].site_artefact_name : local.vpn_connection_dependency_info[c_k].site_id_raw
            location_key            = l_k

            name = coalesce(try(c_v.name, null), c_k)

            # remote_vpn_site_key --> hub object key - remote site artefactName
            remote_vpn_site_key = format(
              "%s-%s",
              k == local.vwan_hub_artefact_default ? "ecpa_${lower(local.vpn_connection_location_map["${l_k}_${c_k}"].location)}_${local.virtual_hub_address_prefix_map["${l_k}_${k}"].address_prefix}" : k,
              local.vpn_connection_dependency_info[c_k].site_is_artefact_ref ? local.vpn_connection_vhub_artefact[c_k].site_artefact_name : local.vpn_connection_dependency_info[c_k].site_id_raw
            )

            internet_security_enabled = null # TODO
            routing                   = null # TODO
            traffic_selector_policy   = null # TODO

            vpn_links = [
              for vl in c_v.vpnLinkConnections :
              {
                name                 = try(vl.name, "link${index(c_v.vpnLinkConnections, vl) + 1}-connection")
                vpn_site_link_number = index(c_v.vpnLinkConnections, vl)
                vpn_site_key = format(
                  "%s-%s",
                  k == local.vwan_hub_artefact_default ? "ecpa_${lower(local.vpn_connection_location_map["${l_k}_${c_k}"].location)}_${local.virtual_hub_address_prefix_map["${l_k}_${k}"].address_prefix}" : k,
                  local.vpn_connection_dependency_info[c_k].site_is_artefact_ref ? local.vpn_connection_vhub_artefact[c_k].site_artefact_name : local.vpn_connection_dependency_info[c_k].site_id_raw
                )

                egress_nat_rule_ids  = null # TODO
                ingress_nat_rule_ids = null # TODO

                bandwidth_mbps  = try(vl.properties.connectionBandwidth, 0)
                bgp_enabled     = try(vl.properties.enableBgp, false)
                connection_mode = try(vl.properties.vpnLinkConnectionMode, "Default")

                protocol = try(vl.properties.vpnConnectionProtocolType, "IKEv2")

                ipsec_policy = try(length(vl.properties.ipsecPolicies), 0) == 0 ? null : {
                  dh_group                 = try(vl.properties.ipsecPolicies[0].dhGroup, "DHGroup24")
                  ike_encryption_algorithm = try(vl.properties.ipsecPolicies[0].ikeEncryption, "AES256")
                  ike_integrity_algorithm  = try(vl.properties.ipsecPolicies[0].ikeIntegrity, "SHA256")
                  encryption_algorithm     = try(vl.properties.ipsecPolicies[0].ipsecEncryption, "GCMAES256")
                  integrity_algorithm      = try(vl.properties.ipsecPolicies[0].ipsecIntegrity, "GCMAES256")
                  pfs_group                = try(vl.properties.ipsecPolicies[0].pfsGroup, "PFS24")
                  sa_data_size_kb          = try(vl.properties.ipsecPolicies[0].saDataSizeKilobytes, 102400000)
                  sa_lifetime_sec          = try(vl.properties.ipsecPolicies[0].saLifeTimeSeconds, 27000)
                }

                ratelimit_enabled = try(vl.properties.enableRateLimiting, false)
                route_weight      = try(vl.properties.routingWeight, 0)
                #     BUG: AVM module (rsp. underlying azurerm resource) will constantly try to change the shared key if set here
                #          --> always leave 'null'
                shared_key = null
                shared_key_object = {
                  # value will be set later from random_password resource
                  value                       = try(vl.properties.preSharedKey.value, null)
                  value_random                = try(vl.properties.preSharedKey.valueRandom, true)
                  value_random_version        = try(vl.properties.preSharedKey.valueRandomVersion, 0)
                  value_key_vault_retrievable = try(vl.properties.preSharedKey.valueKeyVaultRetrievable, true)
                  value_key_vault_read        = try(vl.properties.preSharedKey.valueKeyVaultRead, false)

                }
                local_azure_ip_address_enabled        = try(vl.properties.useLocalAzureIpAddress, false)
                policy_based_traffic_selector_enabled = try(vl.properties.usePolicyBasedTrafficSelectors, false)
                custom_bgp_addresses = [
                  for cbgp in try(vl.properties.customBgpIpAddresses, []) : {
                    ip_address = cbgp.customBgpIpAddress
                    instance   = cbgp.ipConfigurationId
                  }
                ]
              }
            ]
          }
          # add only when location of hub matches
          if local.vpn_connection_location_map["${l_k}_${c_k}"].location == local.virtual_wan_hub_location_map["${l_k}_${k}"].location &&
          # if no GW reference is given, attach to default hub's gateway
          (
            local.vpn_connection_dependency_info[c_k].gw_id_raw == "" ||
            try(local.vpn_gateway_objects_hub_resolved_map["${l_k}_${k}"].virtual_network_gateways.gateway_artefact_key, "") == local.vpn_connection_dependency_info[c_k].gw_id_raw ||
            try(local.vpn_gateway_objects_hub_resolved_map["${l_k}_${k}"].virtual_network_gateways.gateway_artefact_key, "") == local.vpn_connection_vhub_artefact[c_k].gw_artefact_name
          )
        }
      }
    }
  ]

  vpn_connection_objects_hub_resolved_map = zipmap(
    flatten([for entry, attr in local.vpn_connection_objects_hub_resolved_list : keys(attr)]),
    flatten([for entry, attr in local.vpn_connection_objects_hub_resolved_list : values(attr)])
  )
}
