# NOTE: If running via Service Principal, that identity needs to be a member of 'Enterprise Service Accounts'
#     built in DevOps organizational level group
#     otherwise the adding of Entra ID based groups and accounts might fail
data "azuredevops_group" "reference" {

  for_each = local.ado_wid_group_membership_objects

  project_id = each.value["projectId"] #  If project_id is not specified the project collection groups will be searched.
  name       = each.value["displayName"]
}

resource "azuredevops_service_principal_entitlement" "mpool" {
  for_each = local.ado_wid_permission_objects

  origin_id = var.workload_identity_type == "userAssignedIdentity" ? data.azuread_service_principal.mpool[each.key].object_id : var.workload_identity_type == "serviceprincipal" ? azuread_service_principal.mpool[each.key].object_id : "error"
  origin    = "aad"
  # ensure that the service principal has at least a Basic ('express') license. Stakeholder licenses don't provide repository access.
  account_license_type = "express" # "stakeholder"
  licensing_source     = "account"
}

# Organization-wide permission might no longer be required once Azure DevOps Managed Pools support
#     project-level only permissions
resource "azuredevops_group_membership" "mpool" {
  for_each = local.ado_wid_group_membership_objects

  group = data.azuredevops_group.reference[each.key].descriptor
  members = [
    azuredevops_service_principal_entitlement.mpool[each.value["wid_key"]].descriptor
  ]
  mode = "add"
}

########################## Project Permissions ##########################
data "azuredevops_group" "project_reference" {
  for_each = local.ado_wid_project_group_membership_objects

  project_id = each.value["projectId"] #  If project_id is not specified the project collection groups will be searched.
  name       = each.value["displayName"]
}

resource "azuredevops_group_membership" "mpool_project" {
  for_each = local.ado_wid_project_group_membership_objects

  group = data.azuredevops_group.project_reference[each.key].descriptor
  members = [
    azuredevops_service_principal_entitlement.mpool[each.value["wid_key"]].descriptor
  ]
  mode = "add"
}

