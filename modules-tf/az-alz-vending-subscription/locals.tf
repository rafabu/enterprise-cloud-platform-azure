locals {

  # Entra ID Roles and Permissions
  entra_roles_with_permission = {
    lz-owner = {
      name_suffix            = "owner"
      role_member_object_ids = var.workload_owners_group_member_object_ids
      role_owner_object_ids = distinct(concat(
        [azapi_resource.uami.output.properties.principalId],
        var.workload_owners_group_owners_object_ids
      ))
      use_pim = var.workload_owners_group_use_pim
      permanent_permission_member_object_ids = [
        azapi_resource.uami.output.properties.principalId
      ]
      permission_rbac_role_definitions = {
        subscription-owner = {
          definition                = "Subscription-Owner-Role-Restricted (${var.ecp_parent_management_group_name})" # alz provider adds MG id to custom role names
          definition_lookup_enabled = true
          relative_scope            = ""
          # prevent owners to add highly privileged role assignments to the subscription and lower levels (e.g. Owner, User Access Administrator, etc.)
          condition         = <<-EOT
(
  (
   !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
  )
  OR 
  (
    @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAllValues:GuidNotEquals {${join(", ", local.subscription_owner_excluded_assignment_role_ids)}}
  )
)
AND
(
  (
    !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
  )
  OR 
  (
    @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAllValues:GuidNotEquals {${join(", ", local.subscription_owner_excluded_assignment_role_ids)}}
  )
)
EOT
          condition_version = "2.0"
        }
        key-vault-administrator = {
          definition     = "Key Vault Administrator"
          relative_scope = ""
        }
        storage-account-contributor = {
          definition     = "Storage Account Contributor"
          relative_scope = ""
        }
        storage-blob-data-owner = {
          definition     = "Storage Blob Data Owner"
          relative_scope = ""
        }
        virtual-machine-administrator-login = {
          definition     = "Virtual Machine Administrator Login"
          relative_scope = ""
        }
      }
    }
    lz-user = {
      name_suffix            = "user"
      role_member_object_ids = var.workload_users_group_member_object_ids
      role_owner_object_ids = distinct(concat(
        [azapi_resource.uami.output.properties.principalId],
        var.workload_users_group_owners_object_ids
      ))
      use_pim = var.workload_users_group_use_pim
      permanent_permission_member_object_ids = [
        azapi_resource.uami.output.properties.principalId
      ]
      permission_rbac_role_definitions = {
        reader = {
          definition     = "Reader"
          relative_scope = ""
        }
        backup-reader = {
          definition     = "Backup Reader"
          relative_scope = ""
        }
        virtual-machine-user-login = {
          definition     = "Virtual Machine User Login"
          relative_scope = ""
        }
      }
    }
  }

  role_rbac_assignment_definition_list = [
    for role_key, role_value in local.entra_roles_with_permission : {
      for definition_key, definition_value in role_value.permission_rbac_role_definitions :
      "${role_key}-${definition_key}" => merge(
        {
          definition_lookup_enabled = false
          principal_id              = module.entra_id_permissions[role_key].permission_group_object_id
          principalType             = "Group"
          relative_scope            = null
          condition                 = null
          condition_version         = null

        },
        definition_value
      )
    }
  ]
  role_rbac_assignment_definitions = zipmap(
    flatten([for key, attr in local.role_rbac_assignment_definition_list : keys(attr)]),
    flatten([for key, attr in local.role_rbac_assignment_definition_list : values(attr)])
  )

  resource_groups = {
    nwrg = {
      # Make sure to create this if you want to be able to cancel you subscription
      name     = "NetworkWatcherRG"
      location = var.azure_location
    }
    mgmt = {
      name     = "${data.azurecaf_name.rg.result}-mgmt"
      location = var.azure_location
    }
    vnet = {
      name     = "${data.azurecaf_name.rg.result}-vnet"
      location = var.azure_location
    }
  }

  subscription_display_name = replace("${data.azurecaf_name.rg.result}", "-rg-", "-sub-")

  network_security_groups = {
    lz-nsg = {
      name               = data.azurecaf_name.nsg.result
      resource_group_key = "vnet"
      location           = var.azure_location
    }
  }

  virtual_networks = {
    lz-vnet = {
      name               = data.azurecaf_name.vnet.result
      resource_group_key = "vnet"
      address_space      = var.vnet_address_space
      location           = var.azure_location
      # vWAN connect
      vwan_connection_enabled = var.vwan_connect_enabled
      vwan_hub_resource_id = var.vwan_connect_enabled ? try(
        var.vwan_hub_resources_by_location[lower(var.vwan_hub_location)].id,
        try(
          var.vwan_hub_resources_by_location[lower(var.azure_location)].id,
          "NO-vWAN-HUB-RESOURCE-ID"
        )
      ) : null

      # Bastion peering (re-use the "hub network feature)")
      hub_network_resource_id = var.bastion_connect_enabled ? var.bastion_vnet_id : null
      hub_peering_enabled     = var.bastion_connect_enabled
      hub_peering_direction   = var.bastion_connect_enabled ? "both" : null
      hub_peering_name_tohub  = var.bastion_connect_enabled ? "bastionhost_${data.azurecaf_name.vnet.result}_${provider::azurerm::parse_resource_id(var.bastion_vnet_id).resource_name}" : null
      hub_peering_options_tohub = var.bastion_connect_enabled ? {
        allow_forwarded_traffic       = false
        allow_gateway_transit         = false
        allow_virtual_network_access  = true
        do_not_verify_remote_gateways = true
        #     enable_only_ipv6_peering      = optional(bool, false)
        #     local_peered_address_spaces   = optional(list(string), [])
        #     local_peered_subnets          = optional(list(string), [])
        peer_complete_vnets = true
        #     remote_peered_address_spaces  = optional(list(string), [])
        #     remote_peered_subnets         = optional(list(string), [])
        use_remote_gateways = false
      } : null
      hub_peering_name_fromhub = var.bastion_connect_enabled ? "bastionhost_${provider::azurerm::parse_resource_id(var.bastion_vnet_id).resource_name}_${data.azurecaf_name.vnet.result}" : null
      hub_peering_options_fromhub = var.bastion_connect_enabled ? {
        allow_forwarded_traffic       = false
        allow_gateway_transit         = false
        allow_virtual_network_access  = true
        do_not_verify_remote_gateways = true
        # enable_only_ipv6_peering      = optional(bool, false)
        # local_peered_address_spaces   = optional(list(string), [])
        # local_peered_subnets          = optional(list(string), [])
        peer_complete_vnets = true
        # remote_peered_address_spaces  = optional(list(string), [])
        # remote_peered_subnets         = optional(list(string), [])
        use_remote_gateways = false
      } : null

      subnets = {
        for key, val in var.subnet_configuration : key => merge({
          network_security_group = {
            key_reference = "lz-nsg"
          }
          name                                          = val.name
          address_prefixes                              = val.address_prefixes
          private_endpoint_network_policies             = try(val.private_endpoint_network_policies, "Disabled")
          private_link_service_network_policies_enabled = try(val.private_link_service_network_policies_enabled, true)
          default_outbound_access_enabled               = try(val.default_outbound_access_enabled, false)
          service_endpoints                             = try(val.service_endpoints, [])
          delegations = try([for del_key, del_val in val.delegations : {
            name = del_val
            service_delegation = {
              name = del_val
          } }], [])
          # extra attribute to steer creation of private endpoints in this subnet (not consumed by AVM)
          private_endpoint_allocate = try(val.private_endpoint_allocate, false)
          },
          # do not add NAT Gateway link on private endpoint subnet (not required)
          local.nat_gateway_resource_id != null && try(val.private_endpoint_allocate, false) == false ? {
            nat_gateway = {
              id = local.nat_gateway_resource_id
            }
          } : {}
        )
      }
    }
  }

  subnet_resource_ids = distinct(flatten([
    for key, val in local.virtual_networks : [
      for subnet_key, subnet_val in val.subnets : "${module.vending.virtual_network_resource_ids[key]}/subnets/${subnet_val.name}"
    ]
  ]))

  private_endpoint_subnet_resource_ids = distinct(flatten([
    for key, val in local.virtual_networks : [
      for subnet_key, subnet_val in val.subnets : "${module.vending.virtual_network_resource_ids[key]}/subnets/${subnet_val.name}"
      if subnet_val.private_endpoint_allocate == true
    ]
  ]))

  # Flatten additional_entra_id_group_members into all combinations of group_object_id and role_group_key
  additional_entra_id_group_members_flattened = {
    for combination in flatten([
      for group_name, group_data in var.additional_entra_id_group_members : [
        for role_key in group_data.role_group_keys : {
          group_object_id = group_data.group_object_id
          role_group_key  = role_key
          unique_key      = "${group_data.group_object_id}_${role_key}"
        }
      ]
      ]) : combination.unique_key => {
      group_object_id = combination.group_object_id
      role_group_key  = combination.role_group_key
    }
  }
}
