##################################################    Entra ID Groups    ##################################################
# Role
resource "azuread_group" "ecp_deployment_contributor_role" {
  # PIM-able (privileged) group takes naming of permission group as the actual "role" is going to be the candidates for elevation
  display_name            = replace(var.ecp_deployment_entraid_contributor_group_pim_enabled ? "${local.name_template_permission}-privileged" : local.name_template_role, "/<(?:role|permission)>/", "contributor")
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

# resource "azuread_group_member" "workload_contributor_role" {
#   # direct membership only if not using PIM
#   for_each = toset(var.workload_contributors_use_pim == false ? var.workload_contributors : [])

#   group_object_id  = azuread_group.workload_contributor_role.object_id
#   member_object_id = each.key
# }

# resource "azuread_group" "workload_user_role" {
#   # PIM-able (privileged) group takes naming of permission group
#   display_name = replace(var.workload_users_use_pim ? "${local.name_template_permission}-privileged" : local.name_template_role, "/<(?:role|permission)>/", "user")
#   # prevent_duplicate_names = true
#   security_enabled   = true
#   assignable_to_role = var.workload_users_protected

#   owners = [
#     data.azurerm_client_config.current.object_id
#   ]

#   lifecycle {
#     ignore_changes = [
#       owners
#     ]
#   }
# }

# resource "azuread_group_member" "workload_user_role" {
#   # direct membership only if not using PIM
#   for_each = toset(var.workload_users_use_pim == false ? var.workload_users : [])

#   group_object_id  = azuread_group.workload_user_role.object_id
#   member_object_id = each.key
# }
