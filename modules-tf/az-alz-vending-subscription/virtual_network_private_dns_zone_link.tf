resource "azapi_resource" "virtual_network_private_dns_zone_link" {
  for_each = {
    for pair in setproduct(
      keys(module.vending.virtual_network_resource_ids),
      var.private_dns_zone_resource_ids
      ) : "${pair[0]}_${pair[1]}" => {
      virtual_network_key = pair[0]
      virtual_network_id  = module.vending.virtual_network_resource_ids[pair[0]]
      private_dns_zone_id = pair[1]
    }
  }

  type = "Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01"

  name      = "vnet_link-${module.vending.subscription_id}-${each.value.virtual_network_key}"
  parent_id = each.value.private_dns_zone_id
  location  = "global"

  body = {
    properties = {
      registrationEnabled = false
      resolutionPolicy    = "NxDomainRedirect" # When set to 'NxDomainRedirect', Azure DNS resolver falls back to public resolution if private dns query resolution results in non-existent domain response.
      virtualNetwork = {
        id = each.value.virtual_network_id
      }
    }
  }

  # network links do not fully support tags; leave empty.
  tags = {}

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
