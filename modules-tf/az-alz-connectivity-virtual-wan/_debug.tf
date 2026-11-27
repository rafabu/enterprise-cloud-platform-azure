output "zzz_parsed_firewall_artefacts" {
  value = local.parsed_firewall_artefacts
}

output "zzz_parsed_firewall_policy_artefacts" {
  value = local.parsed_firewall_policy_artefacts
}


locals {


  ### Firewall Artefact Processing ###
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

  firewall_hub_resolved_objects_list = [
    for k, v in var.virtual_hub_artefacts : {
      for l_k, l_v in local.hub_locations : "${l_k}_${k}" => {
        firewall = {
          for s_k, s_v in local.parsed_firewall_artefacts : s_k => {
            hub_artefact_key      = k
            firewall_artefact_key = s_k
            location_key          = l_k

            firewall_location = local.firewall_location_map["${l_k}_${s_k}"].location

            name                 = try(s_v.name, null)
            sku_tier             = try(s_v.sku.tier, "Standard")
            vhub_public_ip_count = try(s_v.sku.hubIPAddresses.publicIPs.count, null)
          }
          # add only when location matches hub
          if try(local.firewall_location_map["${l_k}_${s_k}"].location, "") == local.virtual_wan_hub_location_map["${l_k}_${k}"].location
        }
      }
    }
  ]

  firewall_objects_hub_resolved_map = zipmap(
    flatten([for entry, attr in local.firewall_hub_resolved_objects_list : keys(attr)]),
    flatten([for entry, attr in local.firewall_hub_resolved_objects_list : values(attr)])
  )

}

output "zzz_firewall_location_map" {
  value = local.firewall_location_map
}

output "zzz_firewall_objects_hub_resolved_map" {
  value = local.firewall_objects_hub_resolved_map
}
