# NOTE: If running via Service Principal, that identity needs to be a member of 'Enterprise Service Accounts'
#     built in DevOps organizational level group
#     otherwise the adding of Entra ID based groups and accounts might fail
data "azuredevops_group" "reference" {

  for_each = local.ado_wid_group_membership_objects

  project_id = each.value["projectId"] #  If project_id is not specified the project collection groups will be searched.
  name       = each.value["displayName"]
}

# COMMENTED OUT DUE TO PROVIDER INSTABILITY ON LINUX - REPLACED WITH terraform_data IN ado_instable_resources_fix.tf
resource "azuredevops_service_principal_entitlement" "mpool" {
  for_each = local.ado_wid_permission_objects

  origin_id = var.workload_identity_type == "userAssignedIdentity" ? azurerm_user_assigned_identity.mpool[each.key].principal_id : var.workload_identity_type == "serviceprincipal" ? azuread_service_principal.mpool[each.key].object_id : "error"
  origin    = "aad"
  # ensure that the service principal has at least a Basic ('express') license. Stakeholder licenses don't provide repository access.
  account_license_type = "express" # "stakeholder"
  licensing_source     = "account"

  depends_on = [
    time_sleep.wait_after_user_assigned_identity
  ]

  lifecycle {
    # ignore_changes = all
  }
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

  lifecycle {
    # ignore_changes = all
  }
}


######################### Project Permissions ##########################
data "azuredevops_groups" "groups" {
  project_id = local.azure_devops_project.project_id != "00000000-0000-0000-0000-000000000000" ? local.azure_devops_project.project_id : null # route mock project to org-level groups so it doesn't come back empty
}

locals {
  project_references = {
    for key, val in local.ado_wid_project_group_membership_objects :
    key => try([
      for g in data.azuredevops_groups.groups.groups : g if g.display_name == val["displayName"] && data.azuredevops_groups.groups.project_id == val["projectId"]
      ][0], {
      id           = "00000000-0000-0000-0000-000000000000"
      display_name = "mock-group"
      descriptor   = "vssgp.00000000-0000-0000-0000-000000000000"
    })
  }
}

resource "azuredevops_group_membership" "mpool_project" {
  for_each = local.ado_wid_project_group_membership_objects

  group = local.project_references[each.key].descriptor
  members = [
    azuredevops_service_principal_entitlement.mpool[each.value["wid_key"]].descriptor
  ]
  mode = "add"

  lifecycle {
    # ignore_changes = all
  }
}
