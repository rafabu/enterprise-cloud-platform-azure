locals {
  # calculate cidrsubnets on artefacts if required
  virtual_network_address_prefixes = {
    for af in toset(var.virtual_network_artefact_names) : af => {
      addressPrefixes = distinct(concat(
        var.virtual_network_definitions[af].addressSpace.addressPrefixes != null ? var.virtual_network_definitions[af].addressSpace.addressPrefixes : [],
        var.virtual_network_definitions[af].addressSpace.baseAddressOffsets != null ? [
          for bao in var.virtual_network_definitions[af].addressSpace.baseAddressOffsets : cidrsubnet(var.ecp_network_main_ipv4_address_space, bao.newbits, bao.netnum)
        ] : []
      ))
    }
  }

  # check if local IP is within the main ECP Launchpad network
  cidr_string = local.virtual_network_address_prefixes[var.virtual_network_artefact_names[0]].addressPrefixes[0]
  # Split CIDR (network address and mask prefix)
  cidr_base_ip = split("/", local.cidr_string)[0]
  cidr_prefix  = tonumber(split("/", local.cidr_string)[1])
  # Convert IPs to integers for range check
  ip_int   = tonumber(join("", [for octet in split(".", data.external.this_local_ip.result.local_ip) : format("%03d", tonumber(octet))]))
  base_int = tonumber(join("", [for octet in split(".", local.cidr_base_ip) : format("%03d", tonumber(octet))]))
  # Compute upper bound
  ip_count = pow(2, 32 - local.cidr_prefix)
  max_int  = local.base_int + local.ip_count - 1
  # Perform containment check
  ip_is_contained = local.ip_int >= local.base_int && local.ip_int <= local.max_int ? "true" : "false"
}
