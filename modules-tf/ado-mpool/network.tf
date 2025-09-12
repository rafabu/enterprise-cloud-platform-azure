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

data "azapi_resource" "virtual_network" {
  type        = "Microsoft.Network/virtualNetworks@2025-01-01"
  resource_id = var.virtual_network_id

  response_export_values = ["*"]
}


output "subnet_address_prefixes" {
  value = local.subnet_address_prefixes
}
output "virtual_network" {
  value = data.azapi_resource.virtual_network
}

# resource "azurerm_subnet" "mpool" {
#   provider = azurerm.lauchpad

#   for_each = toset(var.subnet_artefact_names)

#   name                 = var.virtual_network_subnet_definitions[each.key].name
#   resource_group_name  = data.azurerm_virtual_network.mpool.resource_group_name
#   virtual_network_name = data.azurerm_virtual_network.mpool.name
#   address_prefixes     = local.subnet_address_prefixes[each.key].addressPrefixes

#   default_outbound_access_enabled   = try(var.virtual_network_subnet_definitions[each.key].defaultOutboundAccess, null)
#   private_endpoint_network_policies = try(var.virtual_network_subnet_definitions[each.key].privateEndpointNetworkPolicies, null)
#   # defaults to true
#   private_link_service_network_policies_enabled = try(var.virtual_network_subnet_definitions[each.key].privateLinkServiceNetworkPolicies, null) == "Disabled" ? false : null
#   # delegation {
#   #   name = "delegation"

#   #   service_delegation {
#   #     name    = "Microsoft.ContainerInstance/containerGroups"
#   #     actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
#   #   }
#   # }
# }
