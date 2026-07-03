locals {
  entra_roles_with_permission = {
    lz-owner = {
      name_suffix = "contributor"
      role_member_object_ids = [
        "86984e3c-69ef-4cf0-9c37-3c5e940408cd", # Raphael Burri (guest user)
        "c17ad8e5-871f-4d00-a6c1-c4b7841dd573", # Lukas Rottach (guest user)
        "678326f7-78a8-4916-83e8-5671ef662b94", # Cédric Mendelin (guest user)
        "27adb7f0-20f5-47aa-b0a6-7f8996b0058f"  # Sebastian Ebner (guest users)
      ]
      use_pim = false
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
      name_suffix = "user"
      role_member_object_ids = [
        "86984e3c-69ef-4cf0-9c37-3c5e940408cd", # Raphael Burri (guest user)
        "c17ad8e5-871f-4d00-a6c1-c4b7841dd573", # Lukas Rottach (guest user)
        "678326f7-78a8-4916-83e8-5671ef662b94", # Cédric Mendelin (guest user)
        "27adb7f0-20f5-47aa-b0a6-7f8996b0058f"  # Sebastian Ebner (guest users)
      ]
      use_pim = false
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
  resource_groups = {
    nwrg = {
      # Make sure to create this if you want to be able to cancel you subscription
      name     = "NetworkWatcherRG"
      location = var.azure_location
    }
    rg1 = {
      name     = "${data.azurecaf_name.rg.result}-spoke1"
      location = var.azure_location
    }
    rg2 = {
      name     = "${data.azurecaf_name.rg.result}-spoke2"
      location = var.azure_location
    }
  }

  role_rbac_assignment_definition_list = [
    for role_key, role_value in local.entra_roles_with_permission : {
      for definition_key, definition_value in role_value.permission_rbac_role_definitions :
      "${role_key}-${definition_key}" => merge(
        {
          definition_lookup_enabled = false
          principal_id      = module.entra_id_permissions[role_key].permission_group_object_id
          principalType     = "Group"
          relative_scope    = null
          condition         = null
          condition_version = null

        },
        definition_value
      )
    }
  ]
  role_rbac_assignment_definitions = zipmap(
    flatten([for key, attr in local.role_rbac_assignment_definition_list : keys(attr)]),
    flatten([for key, attr in local.role_rbac_assignment_definition_list : values(attr)])
  )

  subscription_display_name = "testing-stuff"

  network_security_groups = {
    nsg1 = {
      name               = "nsg-spoke1"
      resource_group_key = "rg1"
      location           = var.azure_location
    }
  }
  virtual_networks = {
    vnet1 = {
      name               = "vnet-spoke1"
      resource_group_key = "rg1"
      address_space      = ["10.1.0.0/24"]
      location           = var.azure_location
      # vWAN connect
      vwan_connection_enabled = true
      vwan_hub_resource_id    = "/subscriptions/54a47b01-be16-4ac5-9c2c-a9847076d794/resourceGroups/iaih-d9-rg-ecpa-con-wan-szn/providers/Microsoft.Network/virtualHubs/iaih-d9-vhub-ecpa-con-szn-01"

      subnets = {
        subnet1 = {
          network_security_group = {
            key_reference = "nsg1"
          }
          name                                          = "number1"
          address_prefixes                              = ["10.1.0.0/27"]
          private_endpoint_network_policies_enabled     = false
          private_link_service_network_policies_enabled = false
          default_outbound_access_enabled               = false
          service_endpoints                             = []
          delegations                                   = []
        }
      }
    }
    # vnet2 = {
    #   name                    = "vnet-spoke2"
    #   resource_group_key      = "rg2"
    #   address_space           = ["10.2.0.0/16"]
    #   hub_network_resource_id = azurerm_virtual_network.hub.id
    # }
  }
}
