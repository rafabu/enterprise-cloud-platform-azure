# user assigned managed identity for each ECP deployment level
#     note: do not make use of service principals to assure no cross-tenant access is possible easily
locals {
  ado_wid_permission_objects = {
    l0-read = {
      azure-roleAssignments = [
        {
          scope = data.azurerm_management_group.ecp_root_parent.id, # ECP root parent management group
          # reader
          roleDefinitionId = "acdd72a7-3385-48ef-bd42-f606fba81ae7", # Reader
          condition        = null
        }
      ],
      ado-memberships = [
        {
          displayName = "Project-Scoped Users" # "Project Collection Service Accounts"
          projectId   = null
        }
      ],
      entra-application-requiredResourceAccess = [
        {
          resourceAppId = "00000003-0000-0000-c000-000000000000", # Microsoft Graph
          resourceAccess = [
            {
              id   = "5b567255-7703-4780-807c-7be8301ae99b", # Group.Read.All
              type = "Role"
            },
            {
              id   = "df021288-bdef-4463-88db-98f22de89214", # User.Read.All
              type = "Role"
            },
            {
              id   = "9a5d68dd-52b0-4cc2-bd40-abcf44ac3a30", # Application.Read.All
              type = "Role"
            },
            {
              id   = "b185aa14-d8d2-42c1-a685-0f5596613624", # CustomSecAttributeDefinition.Read.All
              type = "Role"
            },
            {
              id   = "246dd0d5-5bd0-4def-940b-0421030a5b68", # Policy.Read.All
              type = "Role"
            }
          ]
        }
      ],
      # entra-directory-roleAssignments = [
      #   {
      #     # Global Reader
      #     roleDefinitionId = "f2ef992c-3afb-46b9-b7cf-a126ee74c451",
      #     "directoryScopeId" : "/"
      #   }
      # ],
    }
    l0-contribute = {
      azure-roleAssignments = [
        {
          scope = data.azurerm_management_group.ecp_root_parent.id, # ECP root parent management group
          # contributor
          roleDefinitionId = "b24988ac-6180-42a0-ab88-20f7382dd24c", # Contributor
          condition        = null
        }
      ],
      ado-memberships = [
        {
          displayName = "Enterprise Service Accounts" # "Project Collection Service Accounts"
          projectId   = null
        }
      ],
      entra-application-requiredResourceAccess = [
        {
          resourceAppId = "00000003-0000-0000-c000-000000000000", # Microsoft Graph
          resourceAccess = [
            {
              id   = "5b567255-7703-4780-807c-7be8301ae99b", # Group.Read.All
              type = "Role"
            },
            {
              id   = "df021288-bdef-4463-88db-98f22de89214", # User.Read.All
              type = "Role"
            },
            {
              id   = "1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9", # Application.ReadWrite.All
              type = "Role"
            },
            {
              id   = "06b708a9-e830-4db3-a914-8e69da51d44f", # AppRoleAssignment.ReadWrite.All
              type = "Role"
            },
            {
              id   = "12338004-21f4-4896-bf5e-b75dfaf1016d", # CustomSecAttributeDefinition.ReadWrite.All
              type = "Role"
            },
            {
              id   = "246dd0d5-5bd0-4def-940b-0421030a5b68", # Policy.Read.All
              type = "Role"
            },
            {
              id   = "01c0a623-fc9b-48e9-b794-0756f8e8f067", # Policy.ReadWrite.ConditionalAccess
              type = "Role"
            },
            {
              id   = "1c6e93a6-28e2-4cbb-9f64-1a46a821124d", # Policy.ReadWrite.SecurityDefaults
              type = "Role"
            }

          ]
        }
      ],
      # entra-directory-roleAssignments = [
      #   {
      #     # Global Reader
      #     roleDefinitionId = "f2ef992c-3afb-46b9-b7cf-a126ee74c451",
      #     "directoryScopeId" : "/"
      #   }
      # ],
    }
    l1-read       = {}
    l1-contribute = {}
    # need to enable licenses to have more than 4 (5)
    # l2-read       = {}
    # l2-contribute = {}
  }
  ado_wid_azure_roleassigment_list = [
    for key, val in local.ado_wid_permission_objects : {
      for ra in try(val["azure-roleAssignments"], []) : format("%s_%s", key, sha1(jsonencode(ra))) => merge(
        {
          wid_key = key
        },
        ra
      )
    }
  ]

  ado_wid_azure_roleassigment_objects = zipmap(
    flatten([for key, attr in local.ado_wid_azure_roleassigment_list : keys(attr)]),
    flatten([for key, attr in local.ado_wid_azure_roleassigment_list : values(attr)])
  )
  ado_wid_group_membership_list = [
    for key, val in local.ado_wid_permission_objects : {
      for ra in try(val["ado-memberships"], []) : format("%s_%s", key, sha1(jsonencode(ra))) => merge(
        {
          wid_key = key
        },
        ra
      )
    }
  ]
  ado_wid_group_membership_objects = zipmap(
    flatten([for key, attr in local.ado_wid_group_membership_list : keys(attr)]),
    flatten([for key, attr in local.ado_wid_group_membership_list : values(attr)])
  )
  ado_wid_entra_approle_assignment_list = distinct(flatten([
    for key, val in local.ado_wid_permission_objects : [
      for rra in try(val["entra-application-requiredResourceAccess"], []) : {
        for ra in try(rra["resourceAccess"], []) : format("%s_%s_%s", key, rra["resourceAppId"], sha1(jsonencode(ra))) => merge(
          {
            wid_key            = key
            resource_object_id = rra["resourceAppId"]
          },
          ra
        )
      }
    ]
  ]))

  ado_wid_entra_approle_assignment_objects = zipmap(
    flatten([for key, attr in local.ado_wid_entra_approle_assignment_list : keys(attr)]),
    flatten([for key, attr in local.ado_wid_entra_approle_assignment_list : values(attr)])
  )
}

####################### Azure User Assigned Managed Identity #######################
resource "azurerm_user_assigned_identity" "mpool" {
  provider = azurerm.launchpad

  for_each = {
    for key, val in local.ado_wid_permission_objects : key => val
    if var.workload_identity_type == "userAssignedIdentity"
  }

  location = azurerm_resource_group.mpool.location
  # UAMI does not (yet) exist in provider DS - just rename the RG one...
  name                = format("%s-%s", replace(data.azurecaf_name.rg.result, "-rg-", "-id-"), each.key)
  resource_group_name = azurerm_resource_group.mpool.name
}

# service principals require a while to replicate properly
resource "time_sleep" "wait_after_user_assigned_identity" {
  for_each = {
    for key, val in local.ado_wid_permission_objects : key => val
    if var.workload_identity_type == "userAssignedIdentity"
  }

  create_duration = "2m"

  triggers = {
    client_id = azurerm_user_assigned_identity.mpool[each.key].client_id
  }
}
data "azuread_service_principal" "mpool" {
  for_each = {
    for key, val in local.ado_wid_permission_objects : key => val
    if var.workload_identity_type == "userAssignedIdentity"
  }

  client_id = azurerm_user_assigned_identity.mpool[each.key].client_id

  depends_on = [
    time_sleep.wait_after_user_assigned_identity
  ]
}

####################### Entra Service Principal #######################
resource "azuread_application" "mpool" {
  for_each = {
    for key, val in local.ado_wid_permission_objects : key => val
    if var.workload_identity_type == "serviceprincipal"
  }

  display_name            = format("%s-%s", local.service_principal_name, each.key)
  prevent_duplicate_names = true

  dynamic "required_resource_access" {
    for_each = try(each.value["entra-application-requiredResourceAccess"], {})
    content {
      resource_app_id = required_resource_access.value["resourceAppId"]
      dynamic "resource_access" {
        for_each = try(required_resource_access.value["resourceAccess"], {})
        content {
          id   = resource_access.value["id"]
          type = resource_access.value["type"]
        }
      }
    }
  }

  owners = [
    # data.azurerm_client_config.this.object_id
  ]
}

resource "azuread_service_principal" "mpool" {

  for_each = {
    for key, val in local.ado_wid_permission_objects : key => val
    if var.workload_identity_type == "serviceprincipal"
  }

  client_id                    = azuread_application.mpool[each.key].client_id
  app_role_assignment_required = false
  owners = [
    # data.azurerm_client_config.this.object_id
  ]

  feature_tags {
    enterprise = false
    gallery    = false
    hide       = true
  }
}

####################### Azure RBAC #######################
resource "azurerm_role_assignment" "mpool" {
  provider = azurerm.launchpad

  for_each = local.ado_wid_azure_roleassigment_objects

  scope              = each.value["scope"]
  role_definition_id = format("/providers/Microsoft.Authorization/roleDefinitions/%s", each.value["roleDefinitionId"])
  principal_id       = var.workload_identity_type == "userAssignedIdentity" ? azurerm_user_assigned_identity.mpool[each.value["wid_key"]].principal_id : var.workload_identity_type == "serviceprincipal" ? azuread_service_principal.mpool[each.value["wid_key"]].object_id : "error"
}

####################### Entra App Permission #######################
data "azuread_service_principal" "resource" {
  for_each = {
    for key, val in local.ado_wid_entra_approle_assignment_objects : key => val
    if val["type"] == "Role"
  }

  client_id = each.value["resource_object_id"]
}

# grant app consent (on service principal) respectively add permissions (on user managed identity)
resource "azuread_app_role_assignment" "mpool" {
  for_each = {
    for key, val in local.ado_wid_entra_approle_assignment_objects : key => val
    if val["type"] == "Role"
  }

  app_role_id         = each.value.id
  principal_object_id = var.workload_identity_type == "userAssignedIdentity" ? data.azuread_service_principal.mpool[each.value["wid_key"]].object_id : var.workload_identity_type == "serviceprincipal" ? azuread_service_principal.mpool[each.value["wid_key"]].object_id : "error"
  resource_object_id  = data.azuread_service_principal.resource[each.key].object_id
}
