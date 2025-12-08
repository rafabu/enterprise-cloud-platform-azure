locals {
  # Azure Roles to be assigned to the permission groups at the management group scope
  roles_contributors_management_group = [
    "Contributor",
    "Resource Policy Contributor",
    "User Access Administrator",
    "Key Vault Administrator",
    "Storage Account Contributor",
    "Storage Blob Data Owner",
    "Virtual Machine Administrator Login",
  ]
  roles_readers_management_group = [
    "Reader",
    "Backup Reader",
    "Virtual Machine User Login",
  ]
}

###################### CONTRIBUTOR PERMISSION GROUP ######################

resource "azuread_group_without_members" "contributor_permission" {
  display_name = "${replace(local.name_template_permission_managed, "<permission>", "contributor")}${var.ecp_deployment_entraid_contributor_group_pim_enabled ? "-privileged" : ""}"

  prevent_duplicate_names = true
  security_enabled        = true
  assignable_to_role      = var.ecp_deployment_entraid_contributor_groups_protected

  # with PIM, azuread_privileged_access_group_assignment_schedule resource handles ownership
  owners = var.ecp_deployment_entraid_contributor_group_pim_enabled ? [] : [
    var.ecp_deployment_contributor_workload_identity_object_id
  ]

  lifecycle {
    ignore_changes = [
      owners
    ]
  }
}

resource "azuread_group_member" "contributor_permission_contributor_role" {
  # no direct membership if PIM is used
  for_each = toset(var.ecp_deployment_entraid_contributor_group_pim_enabled ? [] : ["this"])

  group_object_id  = azuread_group_without_members.contributor_permission.object_id
  member_object_id = azuread_group_without_members.contributor_role.object_id
}

resource "azuread_group_member" "contributor_permission_workload_identity_assignment" {
  # with PIM, azuread_privileged_access_group_assignment_schedule resource handles membership
  for_each = toset(var.ecp_deployment_entraid_contributor_group_pim_enabled ? [] : ["this"])

  group_object_id  = azuread_group_without_members.contributor_permission.object_id
  member_object_id = var.ecp_deployment_contributor_workload_identity_object_id
}

resource "azurerm_role_assignment" "contributor_permission" {
  for_each = toset(local.roles_contributors_management_group)

  provider = azurerm.launchpad

  scope                = azurerm_management_group.ecp_deployment_parent.id
  role_definition_name = each.key
  principal_id         = azuread_group_without_members.contributor_permission.object_id
  condition_version    = null
  condition            = null

  depends_on = [
    time_sleep.ecp_deployment_parent
  ]
}

###################### READER PERMISSION GROUP ######################

resource "azuread_group_without_members" "reader_permission" {
  display_name = "${replace(local.name_template_permission_managed, "<permission>", "reader")}${var.ecp_deployment_entraid_reader_group_pim_enabled ? "-privileged" : ""}"

  prevent_duplicate_names = true
  security_enabled        = true
  assignable_to_role      = var.ecp_deployment_entraid_reader_groups_protected

  # with PIM, azuread_privileged_access_group_assignment_schedule resource handles ownership
  owners = var.ecp_deployment_entraid_reader_group_pim_enabled ? [] : [
    var.ecp_deployment_contributor_workload_identity_object_id
  ]

  lifecycle {
    ignore_changes = [
      owners
    ]
  }
}

resource "azuread_group_member" "reader_permission_reader_role" {
  # no direct membership if PIM is used
  for_each = toset(var.ecp_deployment_entraid_reader_group_pim_enabled ? [] : ["this"])

  group_object_id  = azuread_group_without_members.reader_permission.object_id
  member_object_id = azuread_group_without_members.reader_role.object_id
}

# resource "azuread_group_member" "reader_permission_workload_identity_assignment" {
#   # with PIM, azuread_privileged_access_group_assignment_schedule resource handles membership
#   for_each = toset(var.ecp_deployment_entraid_reader_group_pim_enabled ? [] : ["this"])

#   group_object_id  = azuread_group_without_members.reader_permission.object_id
#   member_object_id = var.ecp_deployment_contributor_workload_identity_object_id
# }

resource "azurerm_role_assignment" "reader_permission" {
  for_each = toset(local.roles_readers_management_group)

  provider = azurerm.launchpad

  scope                = azurerm_management_group.ecp_deployment_parent.id
  role_definition_name = each.key
  principal_id         = azuread_group_without_members.reader_permission.object_id
  condition_version    = null
  condition            = null

  depends_on = [
    time_sleep.ecp_deployment_parent
  ]
}
