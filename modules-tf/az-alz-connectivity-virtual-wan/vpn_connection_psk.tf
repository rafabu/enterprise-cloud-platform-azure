# vpn link PSK secrets
locals {
  # construct VPN link connection IDs
  #     and details on shared key
  vpn_link_connection_helper = flatten([
    for k, v in local.vpn_connection_hub_resolved : [
      for sc_key, sc_value in v.vpn_site_connections : {
        for link in sc_value.vpn_links : lower("${k}_${local.virtual_wan_hub_locations[k].location}_${sc_key}_${link.name}") => {
          ecp_artefactName_hub             = k
          ecp_artefactName_site_connection = sc_key
          ecp_location                     = local.virtual_wan_hub_locations[k].location
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
            "${data.azurecaf_name.rg.result}-wan-${lower(local.virtual_wan_hub_locations[k].location)}",
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
          shared_key_object = {
            # priorities:
            #    1. value
            #    2. random value key_vault_retrievable
            #    3. value read from key vault
            value                = try(link.shared_key_object.value, "")
            value_random         = length(try(link.shared_key_object.value, "")) > 0 ? false : try(link.shared_key_object.value_random, true)
            value_random_version = try(link.shared_key_object.value_random_version, 0)
            # generated random password is stored in key vault for reference
            value_key_vault_retrievable = length(try(link.shared_key_object.value, "")) > 0 ? false : try(link.shared_key_object.value_random, true) ? try(link.shared_key_object.value_key_vault_retrievable, true) : false
            # read secret from key vault and use it as preshared key
            value_key_vault_read = length(try(link.shared_key_object.value, "")) > 0 ? false : try(link.shared_key_object.value_random, true) ? try(link.shared_key_object.value_key_vault_read, true) : false
            value_key_vault_secret_name = lower(format(
              # azurerm_key_vault_secret's name to be 1 to 127 chars.
              "psk_%s_%s_%s", # "psk_<location>_<remote site name>_<link connection name>" Example: "psk_switzerlandnorth_ecp-example-static-routing_link1-connection"
              # location
              lower(local.virtual_wan_hub_locations[k].location),
              # remote site name
              local.vpn_site_objects_hub_resolved[k].vpn_sites[replace(link.vpn_site_key, "${k == local.vwan_hub_artefact_default ? "ecpa_${lower(local.virtual_wan_hub_locations[k].location)}" : k}-", "")].name,
              # link connection name
              link.name
            ))
            value_key_vault_secret_content_type = "S2S-VPN-PSK"
          }
        }
      }
    ]
  ])
  vpn_link_connection_helper_object = zipmap(
    flatten([for entry, attr in local.vpn_link_connection_helper : keys(attr)]),
    flatten([for entry, attr in local.vpn_link_connection_helper : values(attr)])
  )
}

output "zzz_zzz_vpn_link_connection_helper_object" {
  value = local.vpn_link_connection_helper_object
}


ephemeral "random_password" "link_connection_shared_key" {
  for_each = { for k, v in local.vpn_link_connection_helper_object : k => v if v.shared_key_object.value_random == true }

  length           = 24
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
  lower            = true
  upper            = true
  numeric          = true
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}


resource "terraform_data" "link_connection_shared_key_version" {
  for_each = {
    for k, v in local.vpn_link_connection_helper_object : k => v
    if v.shared_key_object.value_key_vault_read == false
  }

  input = {
    key_version = each.value.shared_key_object.value_random_version
  }

  triggers_replace = []

  ############################
  ########### NOT (YET) SUPPORTED IN AZAPI PROVIDER ############
  ### see https://github.com/Azure/terraform-provider-azapi/issues/1039

  # action_trigger {
  #   events = [
  #     after_create,
  #     after_update
  #   ]
  #   actions = [
  #     action.azapi_resource_action.vpn_connection_link_preshared_key_put[each.key]
  #   ]
  # }
  # }
}


###### WRITE SHARED KEYS TO KEY VAULT IF REQUIRED ######
resource "azapi_resource" "key_vault_secret_link_connection_shared_key_export" {
  for_each = {
    for k, v in local.vpn_link_connection_helper_object : k => v
    if v.shared_key_object.value_key_vault_retrievable == true &&
    try(length(var.key_vault_id), 0) > 0
  }

  type = "Microsoft.KeyVault/vaults/secrets@2025-05-01"

  parent_id = var.key_vault_id
  name      = each.value.shared_key_object.value_key_vault_secret_name

  body = {
    properties = {
      attributes = {
        enabled = true
        exp     = provider::time::rfc3339_parse(timeadd(plantimestamp(), "8760h")).unix # 1 year
        nbf     = provider::time::rfc3339_parse(plantimestamp()).unix
      }
      contentType = each.value.shared_key_object.value_key_vault_secret_content_type
    }
  }
  sensitive_body = {
    properties = {
      value = ephemeral.random_password.link_connection_shared_key[each.key].result
    }
  }
  sensitive_body_version = {
    "properties.value" = terraform_data.link_connection_shared_key_version[each.key].output.key_version
  }

  ignore_null_property = true
}

###### READ SHARED KEYS FROM KEY VAULT IF REQUIRED ######
ephemeral "azapi_resource_action" "key_vault_secret_link_connection_shared_key_retrieve" {
  for_each = {
    for k, v in local.vpn_link_connection_helper_object : k => v
    if v.shared_key_object.value_key_vault_read == true &&
    length(var.key_vault_id) > 0
  }

  type        = "Microsoft.KeyVault/vaults/secrets@2025-05-01"
  resource_id = "${var.key_vault_id}/secrets/${each.value.shared_key_object.value_key_vault_secret_name}/latest"
  method      = "GET"

  action = ""

  response_export_values = [
    "*"
  ]
}

############################
########### NOT (YET) SUPPORTED IN AZAPI PROVIDER ############
### see https://github.com/Azure/terraform-provider-azapi/issues/1039

# action "azapi_resource_action" "vpn_connection_link_preshared_key_put" {
#   for_each = {
#     for k, v in local.vpn_link_connection_helper_object : k => v
#   }

#   config {
#     type        = "Microsoft.Network/vpnGateways/vpnConnections/vpnLinkConnections/sharedKeys@2025-05-01"
#     resource_id = "${each.value["id"]}/sharedKeys/default"
#     method      = "PUT"

#     body = {
#       properties = {
#       }
#     }
#     # Bummer: An argument named "sensitive_body" is not expected here
#     sensitive_body = {
#       properties = {
#         sharedKey = length(each.value.shared_key_object.value) > 0 ? each.value.shared_key_object.value : each.value.shared_key_object.value_random ? ephemeral.random_password.link_connection_shared_key[each.key].result : ephemeral.azapi_resource_action.key_vault_secret_link_connection_shared_key_retrieve[each.key].response["properties.value"]
#       }
#     }
#   }
# }

# DANGER ZONE: This does update on EVERY apply!!!!
#     currently no way to fix this
# DO NOT ACTIVATE THIS UNLESS YOU ABSOLUTELY HAVE TO FOR DEBUGGING PURPOSES ONLY!!!!
# ephemeral "azapi_resource_action" "vpn_connection_link_preshared_key_put" {
#   for_each = local.vpn_link_connection_helper_object

#   type        = "Microsoft.Network/vpnGateways/vpnConnections/vpnLinkConnections/sharedKeys@2025-05-01"
#   resource_id = "${each.value["id"]}/sharedKeys/default"
#   method      = "PUT"

#   body = {
#     properties = {
#       sharedKey = length(each.value.shared_key_object.value) > 0 ?  each.value.shared_key_object.value : each.value.shared_key_object.value_random ? ephemeral.random_password.link_connection_shared_key[each.key].result : ephemeral.azapi_resource_action.key_vault_secret_link_connection_shared_key_retrieve[each.key].response["properties.value"]
#     }
#   }

#   response_export_values = [
#     "properties.sharedKeyLength"
#   ]

#   depends_on = [
#     module.alz-connectivity-virtual-wan,
#     terraform_data.link_connection_shared_key_version
#   ]
# }
