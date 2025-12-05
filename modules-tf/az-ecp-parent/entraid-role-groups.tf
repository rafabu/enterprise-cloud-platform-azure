###################### CONTRIBUTOR ROLE GROUP ######################

resource "azuread_group_without_members" "contributor_role" {
  # PIM-able (privileged) group takes naming of permission group as the actual "role" is going to be the candidates for elevation
  display_name            = "${replace(local.name_template_role_assignable, "<role>", "contributor")}${var.ecp_deployment_entraid_contributor_group_pim_enabled ? "-eligible" : ""}"
  prevent_duplicate_names = true
  security_enabled        = true
  assignable_to_role      = var.ecp_deployment_entraid_contributor_groups_protected

 owners = [
    var.ecp_deployment_contributor_workload_identity_object_id
  ]

  lifecycle {
    ignore_changes = []
  }
}

resource "azuread_group_member" "contributor_role" {
  for_each = toset(var.ecp_deployment_entraid_contributor_group_member_principal_ids)

  group_object_id  = azuread_group_without_members.contributor_role.object_id
  member_object_id = each.key
}

###################### READER ROLE GROUP ######################

resource "azuread_group_without_members" "reader_role" {
  # PIM-able (privileged) group takes naming of permission group as the actual "role" is going to be the candidates for elevation
  display_name            = "${replace(local.name_template_role_assignable, "<role>", "reader")}${var.ecp_deployment_entraid_reader_group_pim_enabled ? "-eligible" : ""}"
  prevent_duplicate_names = true
  security_enabled        = true
  assignable_to_role      = var.ecp_deployment_entraid_reader_groups_protected

owners = var.ecp_deployment_entraid_reader_group_pim_enabled ? [] : [
    var.ecp_deployment_contributor_workload_identity_object_id
  ]

  lifecycle {
    ignore_changes = []
  }
}

resource "azuread_group_member" "reader_role" {
  for_each = toset(var.ecp_deployment_entraid_reader_group_member_principal_ids)

  group_object_id  = azuread_group_without_members.reader_role.object_id
  member_object_id = each.key
}

