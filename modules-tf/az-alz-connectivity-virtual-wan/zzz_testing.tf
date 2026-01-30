output "zzz_hub_locations" {
  value = local.hub_locations
}


locals {

  virtual_wan_location_list = [
    for k, v in local.parsed_wan_artefacts : {
      for l_k, l_v in local.hub_locations : "${l_k}_${k}" => {
        location = coalesce(
          try(
            lower(v.location) == "default" ? null : v.location,
            null
          ),
          l_v.azure_location
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
    for k, v in local.parsed_wan_artefacts : {
      for l_k, l_v in local.hub_locations : k => {
        location                          = l_v.azure_location
        resource_group_name               = "${data.azurecaf_name.rg.result}-wan-${lower(local.location_code[l_v.azure_location])}"
        type                              = try(v.type, "Standard")
        allow_branch_to_branch_traffic    = try(v.allowBranchToBranchTraffic, true)
        disable_vpn_encryption            = try(v.disableVpnEncryption, false)
        office365_local_breakout_category = try(v.office365LocalBreakoutCategory, "Optimize")
      }
      if try(l_v.is_main_location, false) == true
    }
  ])[0], {})


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
            lower(v.location) == "default" ? null : v.location,
            null
          ),
          l_v.azure_location
        )
      }
    }
  ]
  virtual_wan_hub_location_map = zipmap(
    flatten([for entry, attr in local.virtual_wan_hub_location_list : keys(attr)]),
    flatten([for entry, attr in local.virtual_wan_hub_location_list : values(attr)])
  )






  vpn_gateway_location_list = [
    for k, v in local.parsed_vpn_gateway_artefacts : {
      for l_k, l_v in local.hub_locations : "${l_k}_${k}" => {
        location = coalesce(
          try(
            lower(v.location) == "default" ? null : v.location,
            null
          ),
          l_v.azure_location
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
        virtual_network_gateways = try([
          for gw_k, gw_v in local.parsed_vpn_gateway_artefacts : {
            gateway_key                               = gw_k
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
          try(local.vpn_gateway_location_map["${l_k}_${gw_k}"].location, "") == local.virtual_wan_hub_location_map["${l_k}_${k}"].location
        ][0], null)
      }
    }
  ]
    vpn_gateway_objects_hub_resolved_map = zipmap(
    flatten([for entry, attr in local.vpn_gateway_objects_hub_resolved_list : keys(attr)]),
    flatten([for entry, attr in local.vpn_gateway_objects_hub_resolved_list : values(attr)])
  )

}


output "zzz_virtual_wan_location_map" {
  value = local.virtual_wan_location_map
}


output "zzz_virtual_hub_address_prefix_map" {
  value = local.virtual_hub_address_prefix_map
}

output "zzz_virtual_wan_hub_location_map" {
  value = local.virtual_wan_hub_location_map
}

output "zzz_vpn_gateway_location_map" {
  value = local.vpn_gateway_location_map
}

output "zzz_vpn_gateway_objects_hub_resolved_map" {
  value = local.vpn_gateway_objects_hub_resolved_map
}
