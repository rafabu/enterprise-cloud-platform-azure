# user assigned managed identity for each ECP deployment level
#     note: do not make use of service principals to assure no cross-tenant access is possible easily
locals {
  ado_wid_permission_objects = {
    l0-read = {
      ecp_level = "l0"
      azure-roleAssignments = [
        {
          scope            = data.azurerm_management_group.ecp_root_parent.id, # ECP root parent management group
          roleDefinitionId = "acdd72a7-3385-48ef-bd42-f606fba81ae7",           # Reader
          condition        = null
        },
        {
          scope            = var.backend_storage_accounts["l0"].id,  # backend storage account
          roleDefinitionId = "2a2b9908-6ea1-4ae2-8e65-a410df84e7d1", # Storage Blob Data Reader
          condition        = null
        }
      ],
      ado-memberships = [
        # Organization-wide permission might no longer be required once Azure DevOps Managed Pools support
        #     project-level only permissions
        {
          displayName = "Project-Scoped Users" # "Project Collection Service Accounts"
          projectId   = null
        },
        {
          displayName = "Enterprise Service Accounts" # "--> fix-me and create a lower-priv org-wide group! we need read access on org-level"
          projectId   = null
        }
      ],
      ado-project-memberships = [
        {
          displayName = "Readers"
          projectId   = local.azure_devops_project.project_id
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
            },
            {
              id   = "cd4161cb-f098-48f8-a884-1eda9a42434c", # PrivilegedAssignmentSchedule.Read.AzureADGroup
              type = "Role"
            },
            # azuread_privileged_access_group_assignment_schedule unfortunately needs
            #    PrivilegedAssignmentSchedule.ReadWrite.AzureADGroup
            #    even just for reading (plan)
            {
              id   = "41202f2c-f7ab-45be-b001-85c9728b9d69", # PrivilegedAssignmentSchedule.ReadWrite.AzureADGroup
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
      ecp_level = "l0"
      azure-roleAssignments = [
        {
          scope = data.azurerm_management_group.ecp_root_parent.id, # ECP root parent management group
          # contributor
          roleDefinitionId = "b24988ac-6180-42a0-ab88-20f7382dd24c", # Contributor
          condition        = null
        },
        {
          scope = var.backend_storage_accounts["l0"].id, # backend storage account
          # security reader
          roleDefinitionId = "ba92f5b4-2d11-453d-a403-e96b0029c9fe", # Storage Blob Data Contributor
          condition        = null
        }
      ],
      ado-memberships = [
        # Organization-wide permission might no longer be required once Azure DevOps Managed Pools support
        #     project-level only permissions
        {
          displayName = "Enterprise Service Accounts" # "Project Collection Service Accounts"
          projectId   = null
        }
      ],
      ado-project-memberships = [
        {
          displayName = "Project Administrators"
          projectId   = local.azure_devops_project.project_id
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
            },
            # PIM related roles
            {
              id   = "41202f2c-f7ab-45be-b001-85c9728b9d69", # PrivilegedAssignmentSchedule.ReadWrite.AzureADGroup
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
    # need to enable licenses to have more than 4 (5)
    # l1-read = {
    #   ecp_level = "l1"
    # }
    # l1-contribute = {
    #   ecp_level = "l1"
    # }
    # # need to enable licenses to have more than 4 (5)
    # l2-read = {
    #   ecp_level = "l2"
    # }
    # l2-contribute = {
    #   ecp_level = "l2"
    # }
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
  ado_wid_project_group_membership_list = [
    for key, val in local.ado_wid_permission_objects : {
      for ra in try(val["ado-project-memberships"], []) : format("%s_%s", key, sha1(jsonencode(ra))) => merge(
        {
          wid_key = key
        },
        ra
      )
    }
  ]
  ado_wid_project_group_membership_objects = zipmap(
    flatten([for key, attr in local.ado_wid_project_group_membership_list : keys(attr)]),
    flatten([for key, attr in local.ado_wid_project_group_membership_list : values(attr)])
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

resource "azurerm_federated_identity_credential" "mpool" {
  for_each = {
    for key, val in local.ado_wid_permission_objects : key => val
    if var.workload_identity_type == "userAssignedIdentity"
  }

  provider = azurerm.launchpad

  parent_id           = azurerm_user_assigned_identity.mpool[each.key].id
  name                = "ADO-${var.ecp_azure_devops_organization_name}-${var.ecp_azure_devops_project_name}-${azuredevops_serviceendpoint_azurerm.mpool[each.key].service_endpoint_name}"
  resource_group_name = azurerm_user_assigned_identity.mpool[each.key].resource_group_name

  audience = ["api://AzureADTokenExchange"]
  issuer   = azuredevops_serviceendpoint_azurerm.mpool[each.key].workload_identity_federation_issuer
  subject  = azuredevops_serviceendpoint_azurerm.mpool[each.key].workload_identity_federation_subject

  lifecycle {
    ignore_changes = all
  }

  depends_on = [
    time_sleep.wait_after_user_assigned_identity,
    time_sleep.serviceendpoint_azurerm_pre_destroy_delay
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

resource "azuread_application_federated_identity_credential" "mpool" {
  for_each = {
    for key, val in local.ado_wid_permission_objects : key => val
    if var.workload_identity_type == "serviceprincipal"
  }

  application_id = azuread_application.mpool[each.key].id
  display_name   = "ADO-${var.ecp_azure_devops_organization_name}-${var.ecp_azure_devops_project_name}-${azuredevops_serviceendpoint_azurerm.mpool[each.key].service_endpoint_name}"

  audiences = ["api://AzureADTokenExchange"]
  issuer    = azuredevops_serviceendpoint_azurerm.mpool[each.key].workload_identity_federation_issuer
  subject   = azuredevops_serviceendpoint_azurerm.mpool[each.key].workload_identity_federation_subject

  depends_on = [
    azuread_service_principal.mpool,
    time_sleep.serviceendpoint_azurerm_pre_destroy_delay
  ]
}

locals {
  # unified information about all workload identity service principals
  #   service_principal --> object_id == user_assigned_identity --> principal_id
  workload_identity_objects = merge(
    { for k, v in azurerm_user_assigned_identity.mpool : k => {
      id           = "/servicePrincipals/${v.principal_id}"
      client_id    = v.client_id
      display_name = v.name
      object_id    = v.principal_id
      type         = "ManagedIdentity"
      tenant_id    = data.azurerm_client_config.this.tenant_id
      }
    },
    { for k, v in azuread_service_principal.mpool : k => {
      id           = v.id
      client_id    = v.client_id
      display_name = v.display_name
      object_id    = v.object_id
      type         = "ServicePrincipal"
      tenant_id    = data.azurerm_client_config.this.tenant_id
      }
    }
  )
}

####################### Azure RBAC #######################
resource "azurerm_role_assignment" "mpool" {
  provider = azurerm.launchpad

  for_each = local.ado_wid_azure_roleassigment_objects

  scope = each.value["scope"]
  # if scope is management group, subscription must not be added at the beginning
  role_definition_id = format("%s/providers/Microsoft.Authorization/roleDefinitions/%s", startswith(each.value["scope"], "/subscriptions/") ? data.azapi_client_config.this.subscription_resource_id : "", each.value["roleDefinitionId"])
  principal_id       = var.workload_identity_type == "userAssignedIdentity" ? azurerm_user_assigned_identity.mpool[each.value["wid_key"]].principal_id : var.workload_identity_type == "serviceprincipal" ? azuread_service_principal.mpool[each.value["wid_key"]].object_id : "error"

  depends_on = [
    time_sleep.wait_after_user_assigned_identity
  ]
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
  principal_object_id = var.workload_identity_type == "userAssignedIdentity" ? azurerm_user_assigned_identity.mpool[each.value["wid_key"]].principal_id : var.workload_identity_type == "serviceprincipal" ? azuread_service_principal.mpool[each.value["wid_key"]].object_id : "error"
  resource_object_id  = data.azuread_service_principal.resource[each.key].object_id

  depends_on = [
    time_sleep.wait_after_user_assigned_identity
  ]
}
