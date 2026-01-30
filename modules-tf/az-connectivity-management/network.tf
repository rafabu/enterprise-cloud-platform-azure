resource "azurerm_virtual_network" "mgm" {
  provider = azurerm.connectivity

  for_each = local.virtual_network_address_prefixes_location_object

  name = join("-", compact([
    data.azurecaf_name.vnet.result,
    try(local.parsed_network_artefacts[each.value.artefact_key].nameElement, null),
    local.location_code[lower(local.hub_locations[each.value.location_key].azure_location)]
  ]))
  location            = local.hub_locations[each.value.location_key].azure_location
  resource_group_name = azurerm_resource_group.mgm.name

  address_space = each.value.address_prefixes

  dynamic "encryption" {
    for_each = try(local.parsed_network_artefacts[each.value.artefact_key].encryption.enabled, false) == true ? ["encrypt"] : []
    content {
      enforcement = try(local.parsed_network_artefacts[each.value.artefact_key].encryption.enforcement, "AllowUnencrypted")
    }
  }
  private_endpoint_vnet_policies = try(local.parsed_network_artefacts[each.value.artefact_key].privateEndpointVNetPolicies, null) == "Basic" ? "Basic" : null

  tags = var.azure_tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_subnet" "mgm" {
  provider = azurerm.connectivity

  for_each = local.virtual_network_subnet_address_prefixes_location_object


  name = local.parsed_network_subnet_artefacts[each.value.artefact_key].name
  resource_group_name = azurerm_virtual_network.mgm[join(
    "_",
    [
      each.value.location_key,
      local.parsed_network_subnet_artefacts[each.value.artefact_key].virtualNetwork.artefactName
    ]
  )].resource_group_name
  virtual_network_name = azurerm_virtual_network.mgm[join(
    "_",
    [
      each.value.location_key,
      local.parsed_network_subnet_artefacts[each.value.artefact_key].virtualNetwork.artefactName
    ]
  )].name
  address_prefixes = each.value.address_prefixes

  default_outbound_access_enabled   = try(local.parsed_network_subnet_artefacts[each.value.artefact_key].defaultOutboundAccess, null)
  private_endpoint_network_policies = try(local.parsed_network_subnet_artefacts[each.value.artefact_key].privateEndpointNetworkPolicies, null)
  # defaults to true
  private_link_service_network_policies_enabled = try(local.parsed_network_subnet_artefacts[each.value.artefact_key].privateLinkServiceNetworkPolicies, null) == "Disabled" ? false : null
}
