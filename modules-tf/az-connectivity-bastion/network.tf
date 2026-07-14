resource "azapi_resource" "bast_vnet" {
  for_each = local.virtual_network_address_prefixes_location_object

  type = "Microsoft.Network/virtualNetworks@2025-05-01"
  name = join("-", compact([
    data.azurecaf_name.vnet.result,
    "bastion",
    local.location_code[lower(local.hub_locations[each.value.location_key].azure_location)]
  ]))
  location  = local.hub_locations[each.value.location_key].azure_location
  parent_id = azapi_resource.resource_group.id

  body = {
    properties = {
      addressSpace = {
        addressPrefixes = each.value.address_prefixes
      }
      encryption = try(local.parsed_network_artefacts[each.value.artefact_key].encryption.enabled, false) == true ? {
        enforcement = try(local.parsed_network_artefacts[each.value.artefact_key].encryption.enforcement, "AllowUnencrypted")
      } : null
      privateEndpointVNetPolicies = try(local.parsed_network_artefacts[each.value.artefact_key].privateEndpointVNetPolicies, null) == "Basic" ? "Basic" : "Disabled"
    }
    tags = var.azure_tags
  }

  response_export_values = [
    "*"
  ]

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azapi_resource" "bast_subnet" {
  for_each = local.virtual_network_subnet_address_prefixes_location_object

  type = "Microsoft.Network/virtualNetworks/subnets@2025-05-01"
  name = local.parsed_network_subnet_artefacts[each.value.artefact_key].name
  parent_id = azapi_resource.bast_vnet[each.key].id

  body = {
    properties = {
      addressPrefix                     = each.value.address_prefixes[0]
      defaultOutboundAccess             = try(local.parsed_network_subnet_artefacts[each.value.artefact_key].defaultOutboundAccess, null)
      privateEndpointNetworkPolicies    = try(local.parsed_network_subnet_artefacts[each.value.artefact_key].privateEndpointNetworkPolicies, null)
      privateLinkServiceNetworkPolicies = try(local.parsed_network_subnet_artefacts[each.value.artefact_key].privateLinkServiceNetworkPolicies, null) == "Disabled" ? false : "Enabled"
    }
  }

  response_export_values = [
    "*"
  ]
}
