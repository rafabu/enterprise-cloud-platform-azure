resource "azapi_resource" "bastion" {
  for_each = local.hub_locations

  type = "Microsoft.Network/bastionHosts@2025-07-01" # 2025-09-01 / 2026-01-01
  name = join("-", compact([
    data.azurecaf_name.bas.result,
    "bastion",
    local.location_code[lower(each.value.azure_location)]
  ]))
  location  = each.value.azure_location
  parent_id = azapi_resource.resource_group.id

  body = {
    identity = {
      type = "systemAssigned" # yes: with lowercase "s"
    }

    properties = {
      disableCopyPaste         = false
      enableIpConnect          = false
      enableKerberos           = false
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

  schema_validation_enabled = false

  lifecycle {
    ignore_changes = [
      tags,
      identity["identity_ids"],
      identity["principal_id"],
      identity["tenant_id"]
    ]
  }
}
