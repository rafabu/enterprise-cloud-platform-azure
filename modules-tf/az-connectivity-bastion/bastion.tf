resource "azapi_resource" "bastion" {
  for_each = local.hub_locations

  type = "Microsoft.Network/bastionHosts@2025-05-01"
  name = join("-", compact([
    data.azurecaf_name.bas.result,
    "bastion",
    local.location_code[lower(each.value.azure_location)]
  ]))
  location  = each.value.azure_location
  parent_id = azapi_resource.resource_group.id

  body = {
    properties = {
      disableCopyPaste         = false
      enableIpConnect          = false
      enableKerberos           = true
      enablePrivateOnlyBastion = false
      enableSessionRecording   = false
      enableShareableLink      = false
      enableTunneling          = false
      ipConfigurations = [
        {
          name = "IPConf"
          properties = {
            privateIPAllocationMethod = "Dynamic"
            publicIPAddress = {
              id = azapi_resource.bast_pip[each.key].id
            }
            subnet = {
              id = azapi_resource.bast_subnet[each.key].id
            }
          }
        }
      ]
      #   networkAcls = {
      #     ipRules = [
      #       {
      #         addressPrefix = "string"
      #       }
      #     ]
      #   }
      scaleUnits = 2
      virtualNetwork = {
        id = azapi_resource.bast_vnet[each.key].id
      }
    }
    sku = {
      name = "Basic"
    }
    zones = ["1", "2", "3"]
  }

  tags = var.azure_tags

  response_export_values = ["*"]

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
