resource "azurerm_virtual_network" "mgm" {
  provider = azurerm.connectivity

  for_each = local.parsed_network_artefacts

  name                = "${data.azurecaf_name.vnet.result}-${try(each.value.nameElement, "")}"
  location            = azurerm_resource_group.mgm.location
  resource_group_name = azurerm_resource_group.mgm.name

  address_space = local.virtual_network_address_prefixes[each.key].address_prefixes
  dynamic "encryption" {
    for_each = try(each.value.encryption.enabled, false) == true ? ["encrypt"] : []
    content {
      enforcement = try(each.value.encryption.enforcement, "AllowUnencrypted")
    }
  }
  private_endpoint_vnet_policies = try(each.value.privateEndpointVNetPolicies, null) == "Basic" ? "Basic" : null

  tags = var.azure_tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_subnet" "mgm" {
  provider = azurerm.connectivity

  for_each = local.parsed_network_subnet_artefacts


  name                 = each.value.name
  resource_group_name  = azurerm_virtual_network.mgm[each.value.virtualNetwork.artefactName].resource_group_name
  virtual_network_name = azurerm_virtual_network.mgm[each.value.virtualNetwork.artefactName].name
  address_prefixes     = local.virtual_network_subnet_address_prefixes[each.key].address_prefixes

  default_outbound_access_enabled   = try(each.value.defaultOutboundAccess, null)
  private_endpoint_network_policies = try(each.value.privateEndpointNetworkPolicies, null)
  # defaults to true
  private_link_service_network_policies_enabled = try(each.value.privateLinkServiceNetworkPolicies, null) == "Disabled" ? false : null
}
