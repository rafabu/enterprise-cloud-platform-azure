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

# (Custom) RBAC assignment to the Private DNS Zone resource group(s):
#   allow to contribute DNS records (owner)
#   and read them (user) 
locals {
  private_dns_zone_resource_group_ids = compact(distinct([
    for pdz in var.private_dns_zone_resource_ids : provider::azapi::parse_resource_id("Microsoft.Network/privateDnsZones", pdz).resource_group_id
  ]))
}

resource "azapi_resource" "dns_zone_reader_assignment" {
  for_each = toset(local.private_dns_zone_resource_group_ids)

  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = uuidv5("dns", "${each.key}_${module.entra_id_permissions["lz-user"].permission_group_object_id}./providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7")
  parent_id = each.key
  body = {
    properties = {
      # condition = "string"
      # conditionVersion = "string"
      # delegatedManagedIdentityResourceId = "string"
      description      = "Private DNS Zone Record Reader assignment for Entra group 'lz-user' to read records in private DNS zone"
      principalId      = module.entra_id_permissions["lz-user"].permission_group_object_id
      principalType    = "Group"
      roleDefinitionId = "/subscriptions/${var.ecp_connectivity_subscription_id}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
    }
  }

  lifecycle {
    ignore_changes = [
      body["properties"]["description"]
    ]
  }
}

resource "azapi_resource" "dns_zone_record_contributor_assignment" {
  for_each = toset(local.private_dns_zone_resource_group_ids)

  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = uuidv5("dns", "${each.key}.${module.entra_id_permissions["lz-owner"].permission_group_object_id}.${local.custom_role_definition_privatednszone_record_contributor.id}")
  parent_id = each.key
  body = {
    properties = {
      # condition = "string"
      # conditionVersion = "string"
      # delegatedManagedIdentityResourceId = "string"
      description      = "Private DNS Zone Record Contributor assignment for Entra group 'lz-owner' to manage records in private DNS zone"
      principalId      = module.entra_id_permissions["lz-owner"].permission_group_object_id
      principalType    = "Group"
      roleDefinitionId = "/subscriptions/${var.ecp_connectivity_subscription_id}${local.custom_role_definition_privatednszone_record_contributor.id}"
    }
  }

  lifecycle {
    ignore_changes = [
      body["properties"]["description"]
    ]
  }
}
