# user assigned managed identity for each ECP deployment level
#     note: do not make use of service principals to assure no cross-tenant access is possible easily
locals {
  ado_uamid_objects = {
    l0-read = {
      azure-roleAssignments = [
        {
          scope = data.azurerm_management_group.ecp_root_parent.id,
          # reader
          roleDefinitionId = "acdd72a7-3385-48ef-bd42-f606fba81ae7",
          condition        = null
        }
      ]
    }
    l0-contribute = {
      entra-application-requiredResourceAccess = [
        {
          resourceAppId = "00000003-0000-0000-c000-000000000000",
          resourceAccess = [
            {
              id   = "9a5d68dd-52b0-4cc2-bd40-abcf44ac3a30",
              type = "Role"
            },
            {
              id   = "b185aa14-d8d2-42c1-a685-0f5596613624",
              type = "Role"
            },
            {
              id   = "7ab1d382-f21e-4acd-a863-ba3e13f7da61",
              type = "Role"
            },
            {
              id   = "246dd0d5-5bd0-4def-940b-0421030a5b68",
              type = "Role"
            },
            {
              id   = "01c0a623-fc9b-48e9-b794-0756f8e8f067",
              type = "Role"
            },
            {
              id   = "1c6e93a6-28e2-4cbb-9f64-1a46a821124d",
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
      azure-roleAssignments = [
        {
          scope = data.azurerm_management_group.ecp_root_parent.id,
          # contributor
          roleDefinitionId = "b24988ac-6180-42a0-ab88-20f7382dd24c",
          condition        = null
        }
      ],
      ado-memberships = [
        {

        }
      ]
    }
    l1-read       = {}
    l1-contribute = {}
    l2-read       = {}
    l2-contribute = {}
  }
  ado_uamid_azure_roleassigment_list = [
    for key, val in local.ado_uamid_objects : {
      for ra in try(val["azure-roleAssignments"], []) : format("%s_%s", key, sha1(jsonencode(ra))) => merge(
        {
          uamid_key = key
        },
        ra
      )
    }
  ]
  ado_uamid_azure_roleassigment_objects = zipmap(
    flatten([for key, attr in local.ado_uamid_azure_roleassigment_list : keys(attr)]),
    flatten([for key, attr in local.ado_uamid_azure_roleassigment_list : values(attr)])
  )
}

data "azurerm_management_group" "ecp_root_parent" {
  provider = azurerm.lauchpad

  name = var.ecp_azure_root_parent_management_group_id
}

####################### Azure User Assigned Managed Identity #######################

resource "azurerm_user_assigned_identity" "mpool" {
  provider = azurerm.lauchpad

  for_each = local.ado_uamid_objects

  location = azurerm_resource_group.mpool.location
  # UAMI does not (yet) exist in provider DS - just rename the RG one...
  name                = format("%s-%s", replace(data.azurecaf_name.rg.result, "-rg-", "-id-"), each.key)
  resource_group_name = azurerm_resource_group.mpool.name
}

####################### Azure RBAC #######################
resource "azurerm_role_assignment" "mpool" {
  provider = azurerm.lauchpad

  for_each = local.ado_uamid_azure_roleassigment_objects

  scope              = each.value["scope"]
  role_definition_id = format("/providers/Microsoft.Authorization/roleDefinitions/%s", each.value["roleDefinitionId"])
  principal_id       = azurerm_user_assigned_identity.mpool[each.value["uamid_key"]].principal_id
}
