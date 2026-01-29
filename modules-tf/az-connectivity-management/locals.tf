locals {

  # ECP ARTEFACT DEFAULTS
  parsed_network_artefacts = {
    for k, v in var.virtual_network_artefacts : k => jsondecode(file(v.filePath))
    if lower(var.ecp_archetype_definitions.virtual_network) == lower(k)
  }
  parsed_network_subnet_artefacts = {
    for k, v in var.virtual_network_subnet_artefacts : k => jsondecode(file(v.filePath))
    if contains(var.ecp_archetype_definitions.virtual_network_subnet, k)
  }


  virtual_network_address_prefixes = {
    for k, v in local.parsed_network_artefacts : k => {
      address_prefixes = (
        distinct(concat(
          try([
            for offset in v.addressSpace.baseAddressOffsets :
            cidrsubnet(var.ecp_network_main_ipv4_address_space, offset.newbits, offset.netnum)
          ], [])
        ))
      )
    }
  }
  virtual_network_subnet_address_prefixes = {
    for k, v in local.parsed_network_subnet_artefacts : k => {
      address_prefixes = (
        distinct(concat(
          try([
            for offset in v.baseAddressOffsets :
            cidrsubnet(var.ecp_network_main_ipv4_address_space, offset.newbits, offset.netnum)
          ], [])
        ))
      )
    }
  }
}
