locals {
  location_code = {
    for k, v in module.azure-region-info.regions_by_name : k => coalesce(v.geo_code, v.short_name)
  }

  hub_locations = merge(
    var.azure_location != "" && var.ecp_network_main_ipv4_address_space != "" ? {
      "main" = {
        azure_location                      = lower(var.azure_location)
        ecp_network_main_ipv4_address_space = var.ecp_network_main_ipv4_address_space
        is_main_location                    = true
      }
      } : {
      for k, v in var.ecp_hub_locations : "main" => {
        azure_location                      = lower(v.azure_location)
        ecp_network_main_ipv4_address_space = v.ecp_network_main_ipv4_address_space
        is_main_location                    = coalesce(v.is_main_location, false)
      }
      if coalesce(v.is_main_location, false) == true
    },
    {
      for k, v in var.ecp_hub_locations : k => {
        azure_location                      = lower(v.azure_location)
        ecp_network_main_ipv4_address_space = v.ecp_network_main_ipv4_address_space
        is_main_location                    = coalesce(v.is_main_location, false)
      }
      if coalesce(v.is_main_location, false) == false
    }
  )

  # ECP replacement match pattern
  matchpattern_ecp_artefact  = "(?i)^<ECP_ARTEFACT>:(.+)$"
  matchpattern_ecp_parameter = "(?i)^<ECP_PARAMETER>:(.+)$"

  # Parse all artefact files once
  #    and filter by definition list where needed
  # ECP ARTEFACT DEFAULTS
  parsed_network_artefacts = {
    for k, v in var.virtual_network_artefacts : k => jsondecode(file(v.filePath))
    if lower(var.ecp_archetype_definitions.virtual_network) == lower(k)
  }
  parsed_network_subnet_artefacts = {
    for k, v in var.virtual_network_subnet_artefacts : k => jsondecode(file(v.filePath))
    if contains(var.ecp_archetype_definitions.virtual_network_subnet, k)
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

  virtual_network_address_prefixes_location_list = [
    for k, v in local.parsed_network_artefacts : {
      for l_k, l_v in local.hub_locations : "${l_k}_${k}" => {
        location_key = l_k
        artefact_key = k
        address_prefixes = (
          distinct(concat(
            try([
              for offset in v.addressSpace.baseAddressOffsets :
              cidrsubnet(l_v.ecp_network_main_ipv4_address_space, offset.newbits, offset.netnum)
            ], [])
          ))
        )
      }
    }
  ]
  virtual_network_address_prefixes_location_object = zipmap(
    flatten([for entry, attr in local.virtual_network_address_prefixes_location_list : keys(attr)]),
    flatten([for entry, attr in local.virtual_network_address_prefixes_location_list : values(attr)])
  )
  virtual_network_subnet_address_prefixes_location_list = [
    for k, v in local.parsed_network_subnet_artefacts : {
      for l_k, l_v in local.hub_locations : "${l_k}_${k}" => {
        location_key = l_k
        artefact_key = k
        address_prefixes = (
          distinct(concat(
            try([
              for offset in v.baseAddressOffsets :
              cidrsubnet(l_v.ecp_network_main_ipv4_address_space, offset.newbits, offset.netnum)
            ], [])
          ))
        )
      }
    }
  ]
  virtual_network_subnet_address_prefixes_location_object = zipmap(
    flatten([for entry, attr in local.virtual_network_subnet_address_prefixes_location_list : keys(attr)]),
    flatten([for entry, attr in local.virtual_network_subnet_address_prefixes_location_list : values(attr)])
  )
}


output "zzz_virtual_network_address_prefixes_location_object" {
  value = local.virtual_network_address_prefixes_location_object
}

output "zzz_virtual_network_subnet_address_prefixes_location_object" {
  value = local.virtual_network_subnet_address_prefixes_location_object
}
