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

# mock output-safe resource group info retrieval
#      to allow plan to complete without actual resource group
data "azurerm_resources" "virtual_networks" {
  provider = azurerm.launchpad

  type = "Microsoft.Network/virtualNetworks"
}

locals {
  virtual_network = try([
    for vnet in data.azurerm_resources.virtual_networks.resources : {
      name                = vnet.name
      location            = vnet.location
      resource_group_name = vnet.resource_group_name
    } if vnet.id == var.virtual_network_id][0], {
    name                = "mock-vnet"
    resource_group_name = "mock-rg"
    location            = "westeurope"
  })
}

resource "azurerm_subnet" "devbox" {
  provider = azurerm.launchpad

  for_each = toset(var.subnet_artefact_names)

  name                 = var.virtual_network_subnet_definitions[each.key].name
  resource_group_name  = local.virtual_network.resource_group_name
  virtual_network_name = local.virtual_network.name
  address_prefixes     = local.subnet_address_prefixes[each.key].addressPrefixes

  default_outbound_access_enabled   = try(var.virtual_network_subnet_definitions[each.key].defaultOutboundAccess, null)
  private_endpoint_network_policies = try(var.virtual_network_subnet_definitions[each.key].privateEndpointNetworkPolicies, null)
  # defaults to true
  private_link_service_network_policies_enabled = try(var.virtual_network_subnet_definitions[each.key].privateLinkServiceNetworkPolicies, null) == "Disabled" ? false : null
  delegation {
    name = "Microsoft.DevCenter/networkConnection"
    service_delegation {
      name    = "Microsoft.DevCenter/networkConnection"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}
