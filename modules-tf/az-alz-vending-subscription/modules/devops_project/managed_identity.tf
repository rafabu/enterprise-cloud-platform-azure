##################################################    Identity for Service Connection (UAMI)    ##################################################
#     is being made 'Project Administrator' on new project so service connection will be able to configure
#     the DevOps project accordingly, should users decide to automate their own DevOps Project setup
resource "azapi_resource" "project_uami" {
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30"
  name      = var.managed_identity_name
  parent_id = var.resource_group_id
  location  = var.resource_group_location

  tags = var.resource_group_tags

  response_export_values = [
    "properties.principalId",
    "properties.clientId"
  ]

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azapi_resource" "project_uami_lock" {
  type      = "Microsoft.Authorization/locks@2020-05-01"
  name      = "${var.managed_identity_name}-cannotdelete"
  parent_id = azapi_resource.project_uami.id

  body = {
    properties = {
      level = "CanNotDelete"
      notes = "Prevents accidental deletion of the DevOps project service connection identity"
    }
  }
}

# needs UAMI principal_id, not the client_id
resource "azuredevops_service_principal_entitlement" "project_uami" {
  origin_id = azapi_resource.project_uami.output.properties.principalId
  origin    = "aad"
}

resource "azuredevops_group_membership" "project_uami_project_administrators" {
  group = data.azuredevops_group.project_administrators.descriptor
  members = [
    azuredevops_service_principal_entitlement.project_uami.descriptor
  ]
  mode = "add"
}

# grant it access to subscription (for deployments)
resource "azuread_group_member" "lz_subscription_contributor_permission_project_uami" {
  group_object_id  = var.owner_permission_group_object_id
  member_object_id = azapi_resource.project_uami.output.properties.principalId
}
