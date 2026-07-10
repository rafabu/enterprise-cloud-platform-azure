locals {

  # Entra ID Roles and Permissions
  entra_roles_with_permission = {
    lz-owner = {
      name_suffix            = "owner"
      role_member_object_ids = var.workload_owner_object_ids
      use_pim                = var.workload_owners_use_pim
      pim_permanent_role_member_object_ids = [
        data.azapi_client_config.current.object_id
      ]
      permission_rbac_role_definitions = {
        subscription-owner = {
          definition                = "Subscription-Owner (${var.ecp_parent_management_group_name})" # alz provider adds MG id to custom role names
          definition_lookup_enabled = true
          relative_scope            = ""
          # condition                 = <<-EOT
          # (
          #  (
          #   !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
          #  )
          #  OR 
          #  (
          #   @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAllValues:GuidNotEquals {${join(", ", local.subscription_owner_excluded_assignment_role_ids)}}
          #  )
          # )
          # AND
          # (
          #  (
          #   !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
          #  )
          #  OR 
          #  (
          #   @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAllValues:GuidNotEquals {${join(", ", local.subscription_owner_excluded_assignment_role_ids)}}
          #  )
          # )
          # EOT
          # condition_version         = "2.0"
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
      role_member_object_ids = var.workload_user_object_ids
      use_pim                = var.workload_users_use_pim
      pim_permanent_role_member_object_ids = [
        data.azapi_client_config.current.object_id
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
      vwan_hub_resource_id    = var.vwan_connect_enabled ? var.vwan_hub_resource_id : null

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
}
