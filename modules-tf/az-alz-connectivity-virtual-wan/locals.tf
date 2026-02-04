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

  # Step 1: Parse all artefact files once
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

  ### Virtual Hub Artefact Processing ###
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
}
