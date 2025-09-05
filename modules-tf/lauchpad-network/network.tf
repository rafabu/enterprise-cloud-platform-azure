locals {
  virtual_network_address_prefixes = {
    for af in toset(var.virtual_network_artefact_names) : af => {
      addressPrefixes = concat(
        var.virtual_network_definitions[af].addressSpace.addressPrefixes,
        [
          for bao in var.virtual_network_definitions[af].addressSpace.baseAddressOffsets : cidrsubnet(var.ecp_network_main_ipv4_address_space, bao.newbits, bao.netnum)
        ]
      )
    }
  }
}

resource "azurerm_virtual_network" "lp" {
  provider = azurerm.lauchpad

  for_each = toset(var.virtual_network_artefact_names)

  name                = data.azurecaf_name.vnet[each.key].result
  location            = azurerm_resource_group.lp.location
  resource_group_name = azurerm_resource_group.lp.name

  # address_space = var.virtual_network_definitions[each.key].addressSpace.addressPrefixesconnection {
  address_space = local.virtual_network_address_prefixes[each.key].addressPrefixes

  encryption {
    enforcement = "AllowUnencrypted"
  }
  private_endpoint_vnet_policies = "Disabled"

  tags = var.azure_tags
}



