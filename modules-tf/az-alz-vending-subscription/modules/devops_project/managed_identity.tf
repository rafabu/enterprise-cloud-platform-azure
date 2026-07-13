##################################################    Identity for Service Connection (UAMI)    ##################################################
#     is being made 'Project Administrator' on new project so service connection will be able to configure
#     the DevOps project accordingly, should users decide to automate their own DevOps Project setup

# needs UAMI principal_id, not the client_id
resource "azuredevops_service_principal_entitlement" "project_uami" {
  origin_id = var.managed_identity_object_id
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
  member_object_id = var.managed_identity_object_id
}
