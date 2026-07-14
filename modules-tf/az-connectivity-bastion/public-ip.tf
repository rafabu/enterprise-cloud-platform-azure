resource "azapi_resource" "bast_pip" {
  for_each = local.hub_locations

  type = "Microsoft.Network/publicIPAddresses@2025-05-01"
  name = join("-", compact([
    data.azurecaf_name.pip.result,
    "bastion",
    local.location_code[lower(each.value.azure_location)]
  ]))
  location  = each.value.azure_location
  parent_id = azapi_resource.resource_group.id

  body = {
    properties = {
      ddosSettings = {
        protectionMode = "VirtualNetworkInherited"
      }
      idleTimeoutInMinutes     = 4
      publicIPAddressVersion   = "IPv4"
      publicIPAllocationMethod = "Static"
    }
    sku = {
      name = "Standard" # "StandardV2" isn't yet supported with Bastion
      tier = "Regional"
    }

    zones = ["1", "2", "3"]

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


