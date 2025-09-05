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

resource "azurerm_virtual_network" "lp" {
  provider = azurerm.lauchpad

  for_each = toset(var.virtual_network_artefact_names)

  name                = data.azurecaf_name.vnet[each.key].result
  location            = azurerm_resource_group.lp.location
  resource_group_name = azurerm_resource_group.lp.name

  address_space = local.virtual_network_address_prefixes[each.key].addressPrefixes
  dynamic "encryption" {
    for_each = try(var.virtual_network_definitions[each.key].encryption.enabled, false) == true ? ["encrypt"] : []
    content {
      enforcement = try(var.virtual_network_definitions[each.key].encryption.enforcement, "AllowUnencrypted")
    }
  }
  private_endpoint_vnet_policies = try(var.virtual_network_definitions[each.key].privateEndpointVNetPolicies, null) == "Basic" ? "Basic" : null

  tags = var.azure_tags
}

resource "azurerm_subnet" "lp" {
  provider = azurerm.lauchpad

  for_each = toset(var.subnet_artefact_names)

  name                 = var.virtual_network_subnet_definitions[each.key].name
  resource_group_name  = azurerm_virtual_network.lp[var.virtual_network_subnet_definitions[each.key].virtualNetwork.artefactName].resource_group_name
  virtual_network_name = azurerm_virtual_network.lp[var.virtual_network_subnet_definitions[each.key].virtualNetwork.artefactName].name
  address_prefixes     = local.subnet_address_prefixes[each.key].addressPrefixes

  default_outbound_access_enabled   = try(var.virtual_network_subnet_definitions[each.key].defaultOutboundAccess, null)
  private_endpoint_network_policies = try(var.virtual_network_subnet_definitions[each.key].privateEndpointNetworkPolicies, null)
  # defaults to true
  private_link_service_network_policies_enabled = try(var.virtual_network_subnet_definitions[each.key].privateLinkServiceNetworkPolicies, null) == "Disabled" ? false : null
  # delegation {
  #   name = "delegation"

  #   service_delegation {
  #     name    = "Microsoft.ContainerInstance/containerGroups"
  #     actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
  #   }
  # }
}

# pull data back for output (which includes subnets that have been created)
data "azurerm_virtual_network" "lp" {
  provider = azurerm.lauchpad

  for_each = toset(var.virtual_network_artefact_names)

  name                = azurerm_virtual_network.lp[each.key].name
  resource_group_name = azurerm_virtual_network.lp[each.key].resource_group_name

  depends_on = [azurerm_subnet.lp]
}

output "data" {
  value = data.azurerm_virtual_network.lp
}
