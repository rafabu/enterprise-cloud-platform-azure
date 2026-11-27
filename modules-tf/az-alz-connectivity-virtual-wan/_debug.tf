output "zzz_parsed_firewall_artefacts" {
    value = local.parsed_firewall_artefacts
}

output "zzz_parsed_firewall_policy_artefacts" {
    value = local.parsed_firewall_policy_artefacts
}


locals {


### Firewall Artefact Processing ###
  firewall_vhub_info = {
    for k, v in local.parsed_firewall_artefacts : k => {
      raw_hub_id      = v.virtualHub.id
      is_artefact_ref = can(regex(local.matchpattern_ecp_artefact, v.virtualHub.id))
    }
  }

  firewall_vhub_artefact = {
    for k, v in local.firewall_vhub_info : k => {
      artefact_name = v.is_artefact_ref ? regex(local.matchpattern_ecp_artefact, v.raw_hub_id)[0] : local.vwan_hub_artefact_default
    }
  }

  firewall_location_list = [
    for k, v in local.parsed_firewall_artefacts : {
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

  firewall_location_map = zipmap(
    flatten([for entry, attr in local.firewall_location_list : keys(attr)]),
    flatten([for entry, attr in local.firewall_location_list : values(attr)])
  )

#   vpn_gateway_objects_hub_resolved_list = [
#     for k, v in var.virtual_hub_artefacts : {
#       for l_k, l_v in local.hub_locations : "${l_k}_${k}" => {
#         # not a map despite the plural - needs a single object per hub
#         virtual_network_gateways = try(
#           [
#             for gw_k, gw_v in local.parsed_vpn_gateway_artefacts : {
#               hub_artefact_key     = k
#               gateway_artefact_key = gw_k
#               location_key         = l_k

#               subnet_address_prefix                     = null
#               subnet_default_outbound_access_enabled    = null
#               route_table_creation_enabled              = null
#               route_table_name                          = null
#               route_table_bgp_route_propagation_enabled = null

#               vpn = {
#                 # deterministic naming, following the pattern of wan-hub
#                 name = k == local.vwan_hub_artefact_default ? "${replace(data.azurecaf_name.vwan.result, "-vwan-", "-vpng-")}-${lower(local.location_code[local.virtual_wan_hub_location_map["${l_k}_${k}"].location])}-01" : "${replace(data.azurecaf_name.vwan.result, "-vwan-", "-vpng-")}-${lower(local.location_code[local.virtual_wan_hub_location_map["${l_k}_${k}"].location])}-${format("%02d", random_integer.virtual_hub_id["${l_k}_${k}"].result)}"

#                 bgp_route_translation_for_nat_enabled = try(gw_v.enableBgpRouteTranslationForNat, false)
#                 bgp_settings = {
#                   instance_0_bgp_peering_address = try([
#                     for bgp_pa in try(gw_v.bgpSettings.bgpPeeringAddresses, []) : {
#                       custom_ips = try(bgp_pa.customBgpIpAddresses, [])
#                     }
#                     if try(bgp_pa.ipconfigurationId, "") == "Instance0"
#                   ][0], { custom_ips = [] })
#                   instance_1_bgp_peering_address = try([
#                     for bgp_pa in try(gw_v.bgpSettings.bgpPeeringAddresses, []) : {
#                       custom_ips = try(bgp_pa.customBgpIpAddresses, [])
#                     }
#                     if try(bgp_pa.ipconfigurationId, "") == "Instance1"
#                   ][0], { custom_ips = [] })
#                   peer_weight = coalesce(try(gw_v.bgpSettings.peerWeight, null), 0)
#                   asn         = coalesce(try(gw_v.bgpSettings.asn, null), 65515)
#                 }
#                 routing_preference = try(gw_v.isRoutingPreferenceInternet, false) ? "Internet" : "Microsoft Network"
#                 scale_unit         = coalesce(try(gw_v.vpnGatewayScaleUnit, null), 1)
#               }
#             }
#             # add only when hub artefact && location matches
#             if try(local.vpn_gateway_vhub_artefact[gw_k].artefact_name, "") == k &&
#             try(local.vpn_gateway_location_map["${l_k}_${gw_k}"].location, "") == local.virtual_wan_hub_location_map["${l_k}_${k}"].location
#           ][0],
#           # if connections are defined, we need at least a default gateway object for its name
#           # otherwise, no deployment is needed
#           {
#             hub_artefact_key     = k
#             gateway_artefact_key = "default"
#             location_key         = l_k

#             vpn = {
#               # deterministic naming, following the pattern of wan-hub
#               name = k == local.vwan_hub_artefact_default ? "${replace(data.azurecaf_name.vwan.result, "-vwan-", "-vpng-")}-${lower(local.location_code[local.virtual_wan_hub_location_map["${l_k}_${k}"].location])}-01" : "${replace(data.azurecaf_name.vwan.result, "-vwan-", "-vpng-")}-${lower(local.location_code[local.virtual_wan_hub_location_map["${l_k}_${k}"].location])}-${format("%02d", random_integer.virtual_hub_id["${l_k}_${k}"].result)}"
#             }
#           }
#         )
#       }
#     }
#   ]

#   vpn_gateway_objects_hub_resolved_map = zipmap(
#     flatten([for entry, attr in local.vpn_gateway_objects_hub_resolved_list : keys(attr)]),
#     flatten([for entry, attr in local.vpn_gateway_objects_hub_resolved_list : values(attr)])
#   )

}

output "zzz_firewall_vhub_info" {
  value = local.firewall_vhub_info
}

output "zzz_firewall_location_map" {
  value = local.firewall_location_map
}

output "zzz_firewall_vhub_artefact" {
  value = local.firewall_vhub_artefact
}