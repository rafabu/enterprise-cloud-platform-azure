# vpn link PSK secrets
locals {
  # construct VPN link connection IDs
  vpn_link_connection_helper = flatten([
    for k, v in local.vpn_connection_hub_resolved : [
      for sc_key, sc_value in v.vpn_site_connections : {
        for link in sc_value.vpn_links : "${k}-${sc_key}-${link.name}" => {
          ecp_artefactName_hub             = k
          ecp_artefactName_site_connection = sc_key
          vpn_gateway_name = provider::azapi::parse_resource_id(
            "Microsoft.Network/vpnGateways",
            data.azapi_resource.virtual_wan_hub_details[
              k == local.vwan_hub_artefact_default ? "ecpa_${lower(local.vpn_connection_location_info[sc_key].location)}" : k
            ].output.properties.vpnGateway.id
          ).name
          vpn_connection_name      = sc_value.name
          vpn_connection_link_name = link.name
          # as vpn_gateway is not in AVM output, need to jump through a few hoops to get the vpnGateway ID
          #     and then construct the connection link IDs
          id = provider::azapi::resource_group_resource_id(
            var.ecp_connectivity_subscription_id,
            "${data.azurecaf_name.rg.result}-vwan-${lower(local.virtual_wan_hub_locations[k].location)}",
            "Microsoft.Network/vpnGateways/vpnConnections/vpnLinkConnections",
            [
              provider::azapi::parse_resource_id(
                "Microsoft.Network/vpnGateways",
                data.azapi_resource.virtual_wan_hub_details[
                  k == local.vwan_hub_artefact_default ? "ecpa_${lower(local.vpn_connection_location_info[sc_key].location)}" : k
                ].output.properties.vpnGateway.id
              ).name,
              sc_value.name,
              link.name
            ]
          )
          shared_key = sensitive("shared_key")
        }
      }
    ]
  ])
  vpn_link_connection_helper_object = zipmap(
    flatten([for entry, attr in local.vpn_link_connection_helper : keys(attr)]),
    flatten([for entry, attr in local.vpn_link_connection_helper : values(attr)])
  )
}

resource "azapi_resource_action" "vpn_connection_link_preshared_key" {
  for_each = local.vpn_link_connection_helper_object

  type = "Microsoft.Network/vpnGateways/vpnConnections/vpnLinkConnections/sharedKeys@2025-03-01"
  # resource_id = "/subscriptions/2ad5a985-e423-4a91-aea0-248c51b2e1cc/resourceGroups/rabu-d7-rg-ecpa-conn-vwan-switzerlandnorth/providers/Microsoft.Network/vpnGateways/rabu-d7-vgw-ecpa-conn-vpn-switzerlandnorth-01/vpnConnections/l2-connectivity-example-vpnConnection/vpnLinkConnections/link1-connection/sharedKeys/default"
  resource_id = "${each.value["id"]}/sharedKeys/default"
  method      = "PUT"

  body = {
    properties = {
      sharedKey = each.value["shared_key"]
    }
  }

  response_export_values = [
    "properties.sharedKeyLength"
  ]

  depends_on = [
    module.alz-connectivity-virtual-wan
  ]
}

output "zzz_vpn_connection_link_preshared_key_length" {
  value = {
    for k, v in azapi_resource_action.vpn_connection_link_preshared_key : k => v.output.properties.sharedKeyLength
  }
  description = "The ID of the VPN connection link shared key resource."
  # sensitive   = false
}
