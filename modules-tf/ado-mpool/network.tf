locals {
  # calculate cidrsubnets on artefacts if required
  subnet_address_prefixes = {
    for af in toset(var.subnet_artefact_names) : af => {
      addressPrefixes = distinct(concat(
        var.virtual_network_subnet_definitions[af].addressPrefixes != null ? var.virtual_network_subnet_definitions[af].addressPrefixes : [],
        var.virtual_network_subnet_definitions[af].baseAddressOffsets != null ? [
          for bao in var.virtual_network_subnet_definitions[af].baseAddressOffsets : cidrsubnet(var.ecp_network_main_ipv4_address_space, bao.newbits, bao.netnum)
        ] : []
      ))
    }
  }
}

data "azurerm_virtual_network" "mpool" {
  provider = azurerm.launchpad

  name                = provider::azurerm::parse_resource_id(var.virtual_network_id).resource_name
  resource_group_name = provider::azurerm::parse_resource_id(var.virtual_network_id).resource_group_name
}


resource "azurerm_subnet" "mpool" {
  provider = azurerm.launchpad

  for_each = toset(var.subnet_artefact_names)

  name                 = var.virtual_network_subnet_definitions[each.key].name
  resource_group_name  = data.azurerm_virtual_network.mpool.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.mpool.name
  address_prefixes     = local.subnet_address_prefixes[each.key].addressPrefixes

  default_outbound_access_enabled   = try(var.virtual_network_subnet_definitions[each.key].defaultOutboundAccess, null)
  private_endpoint_network_policies = try(var.virtual_network_subnet_definitions[each.key].privateEndpointNetworkPolicies, null)
  # defaults to true
  private_link_service_network_policies_enabled = try(var.virtual_network_subnet_definitions[each.key].privateLinkServiceNetworkPolicies, null) == "Disabled" ? false : null
  delegation {
    name = "Microsoft.DevOpsInfrastructure/pools"
    service_delegation {
      name    = "Microsoft.DevOpsInfrastructure/pools"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}
