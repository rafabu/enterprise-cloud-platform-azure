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
      disableCopyPaste         = var.azure_bastion_configuration.sku == "Basic" ? false : var.azure_bastion_configuration.copy_paste_disabled
      enableIpConnect          = var.azure_bastion_configuration.sku == "Basic" ? false : var.azure_bastion_configuration.ip_connect_enabled
      enableKerberos           = var.azure_bastion_configuration.sku == "Basic" ? false : var.azure_bastion_configuration.kerberos_enabled
      enablePrivateOnlyBastion = var.azure_bastion_configuration.sku == "Basic" ? false : var.azure_bastion_configuration.private_only_bastion_enabled
      enableSessionRecording   = var.azure_bastion_configuration.sku == "Premium" ? var.azure_bastion_configuration.session_recording_enabled : false
      enableShareableLink      = var.azure_bastion_configuration.sku == "Basic" ? false : var.azure_bastion_configuration.shareable_link_enabled
      enableTunneling          = var.azure_bastion_configuration.sku == "Basic" ? false : var.azure_bastion_configuration.tunneling_enabled

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
      scaleUnits = var.azure_bastion_configuration.sku == "Basic" ? 2 : var.azure_bastion_configuration.scale_units
      virtualNetwork = {
        id = azapi_resource.bast_vnet[each.key].id
      }
    }
    sku = {
      name = var.azure_bastion_configuration.sku
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
