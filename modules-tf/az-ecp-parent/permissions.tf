locals {
  roles_contributors_management_group = [
    "Contributor",
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

##################################################    Entra ID Groups    ##################################################
#                                                        Role
resource "azuread_group" "ecp_deployment_contributor_role" {
  # PIM-able (privileged) group takes naming of permission group as the actual "role" is going to be the candidates for elevation
  # display_name            = replace(var.ecp_deployment_entraid_contributor_group_pim_enabled ? "${local.name_template_permission}-privileged" : local.name_template_role, "/<(?:role|permission)>/", "contributor")
  display_name            = "${replace(local.name_template_role, "<role>", "contributor")}-mg-${var.ecp_deployment_entraid_contributor_group_pim_enabled ? "-eligible" : ""}"
  prevent_duplicate_names = true
  security_enabled        = true
  assignable_to_role      = var.ecp_deployment_entraid_contributor_group_protected

  owners = [
    var.ecp_deployment_contributor_workload_identity_object_id
  ]

  lifecycle {
    ignore_changes = [
      # owners
    ]
  }
}

# resource "azuread_group_member" "ecp_deployment_contributor_role" {
#   # direct membership only if not using PIM
#   for_each = toset(var.ecp_deployment_contributors_use_pim == false ? var.ecp_deployment_contributors : [])

#   group_object_id  = azuread_group.ecp_deployment_contributor_role.object_id
#   member_object_id = each.key
# }

resource "azuread_group" "ecp_deployment_reader_role" {
  # PIM-able (privileged) group takes naming of permission group
  # display_name = replace(var.ecp_deployment_entraid_reader_group_pim_enabled ? "${local.name_template_permission}-privileged" : local.name_template_role, "/<(?:role|permission)>/", "reader")
  display_name = "${replace(local.name_template_role, "<role>", "reader")}-mg-${var.ecp_deployment_entraid_reader_group_pim_enabled ? "-eligible" : ""}"

  # prevent_duplicate_names = true
  security_enabled   = true
  assignable_to_role = var.ecp_deployment_entraid_reader_group_protected

  owners = [
    var.ecp_deployment_contributor_workload_identity_object_id
  ]

  lifecycle {
    ignore_changes = [
      members,
      # owners
    ]
  }
}

# resource "azuread_group_member" "ecp_deployment_reader_role" {
#   # direct membership only if not using PIM
#   for_each = toset(var.ecp_deployment_entraid_reader_group_pim_enabled == false ? var.ecp_deployment_readers : [])

#   group_object_id  = azuread_group.ecp_deployment_reader_role.object_id
#   member_object_id = each.key
# }



#                                                        Permissions
resource "azuread_group" "ecp_deployment_contributor_permission" {
  # display_name            = replace(local.name_template_permission, "<permission>", "contributor")
  display_name = "${replace(local.name_template_permission, "<permission>", "contributor")}-mg-${var.ecp_deployment_entraid_contributor_group_pim_enabled ? "-privileged" : ""}"

  prevent_duplicate_names = true
  security_enabled        = true
  assignable_to_role      = var.ecp_deployment_entraid_contributor_group_protected

  owners = [
    var.ecp_deployment_contributor_workload_identity_object_id
  ]

  lifecycle {
    ignore_changes = [
      # owners
    ]
  }
}

resource "azuread_group_member" "ecp_deployment_contributor_permission_contributor_role" {
  # no direct membership if PIM is used
  for_each = toset(var.ecp_deployment_entraid_contributor_group_pim_enabled ? [] : ["this"])

  group_object_id  = azuread_group.ecp_deployment_contributor_permission.object_id
  member_object_id = azuread_group.ecp_deployment_contributor_role.object_id
}

resource "azuread_group_member" "ecp_deployment_contributor_permission_workload_identity_assignment" {
  # with PIM, azuread_privileged_access_group_assignment_schedule resource handles membership
  for_each = toset(var.ecp_deployment_entraid_contributor_group_pim_enabled ? [] : ["this"])

  group_object_id  = azuread_group.ecp_deployment_contributor_permission.object_id
  member_object_id = var.ecp_deployment_contributor_workload_identity_object_id
}

resource "azurerm_role_assignment" "ecp_deployment_contributor_permission" {
  for_each = toset(local.roles_contributors_management_group)

  provider = azurerm.launchpad

  scope                = azurerm_management_group.ecp_deployment_parent.id
  role_definition_name = each.key
  principal_id         = azuread_group.ecp_deployment_contributor_permission.object_id
  condition_version    = null
  condition            = null

  depends_on = [
    time_sleep.ecp_deployment_parent
  ]
}

resource "azuread_group" "ecp_deployment_reader_permission" {
  # display_name            = replace(local.name_template_permission, "<permission>", "reader")
  display_name            = "${replace(local.name_template_permission, "<permission>", "reader")}-mg-${var.ecp_deployment_entraid_reader_group_pim_enabled ? "-privileged" : ""}"
  prevent_duplicate_names = true
  security_enabled        = true
  assignable_to_role      = var.ecp_deployment_entraid_reader_group_protected
  owners = [
    var.ecp_deployment_contributor_workload_identity_object_id
  ]

  lifecycle {
    ignore_changes = [
      # owners
    ]
  }
}

resource "azuread_group_member" "ecp_deployment_reader_permission_reader_role" {
  # no direct membership if PIM is used
  for_each = toset(var.ecp_deployment_entraid_reader_group_pim_enabled ? [] : ["this"])

  group_object_id  = azuread_group.ecp_deployment_reader_permission.object_id
  member_object_id = azuread_group.ecp_deployment_reader_role.object_id
}

resource "azuread_group_member" "ecp_deployment_reader_permission_workload_identity_assignment" {
  # with PIM, azuread_privileged_access_group_assignment_schedule resource handles membership
  for_each = toset(var.ecp_deployment_entraid_reader_group_pim_enabled ? [] : ["this"])

  group_object_id  = azuread_group.ecp_deployment_reader_permission.object_id
  member_object_id = var.ecp_deployment_reader_workload_identity_object_id
}

resource "azurerm_role_assignment" "ecp_deployment_reader_permission" {
  for_each = toset(local.roles_readers_management_group)

  provider = azurerm.launchpad

  scope                = azurerm_management_group.ecp_deployment_parent.id
  role_definition_name = each.key
  principal_id         = azuread_group.ecp_deployment_reader_permission.object_id
  condition_version    = null
  condition            = null

  depends_on = [
    time_sleep.ecp_deployment_parent
  ]
}
