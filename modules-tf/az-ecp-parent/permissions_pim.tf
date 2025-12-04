################################
# Privileged Identity Management
################################

##################################################    Entra ID Groups (eligible)   ##################################################
# Eligible Principals Group
# resource "azuread_group" "ecp_deployment_contributor_role_eligible" {
#   for_each = toset(var.ecp_deployment_entraid_contributor_group_pim_enabled ? ["this"] : [])

#   display_name = "${replace(local.name_template_role, "<role>", "contributor")}-eligible"

#   prevent_duplicate_names = true
#   security_enabled        = true
#   assignable_to_role      = var.ecp_deployment_entraid_contributor_group_protected

#   owners = [
#     var.ecp_deployment_contributor_workload_identity_object_id
#   ]

#   lifecycle {
#     ignore_changes = [
#       # owners
#     ]
#   }
# }

# # set members of the "eligible" group (users allowed to activate the privileged group membership)
# resource "azuread_group_member" "ecp_deployment_contributor_role_eligible" {
#   # interactive users only
#   for_each = toset(var.ecp_deployment_entraid_contributor_group_pim_enabled ? var.ecp_deployment_contributors : [])

#   group_object_id  = azuread_group.ecp_deployment_contributor_role_eligible["this"].object_id
#   member_object_id = each.key
# }

##################################################    PIM Policy & Schedules   ##################################################
# Configure PIM eligibility policy for the group
resource "time_sleep" "ecp_deployment_contributor_replication_wait" {
  for_each = toset(var.ecp_deployment_entraid_contributor_group_pim_enabled ? ["this"] : [])

  depends_on = [
    azuread_group.ecp_deployment_contributor_role,
    azuread_group.ecp_deployment_contributor_permission
  ]

  create_duration = "60s"
}

resource "azuread_group_role_management_policy" "ecp_deployment_contributor_permission_policy" {
  for_each = toset(var.ecp_deployment_entraid_contributor_group_pim_enabled ? ["this"] : [])

  group_id = azuread_group.ecp_deployment_contributor_permission.object_id
  role_id  = "member"

  activation_rules {
    maximum_duration      = "PT4H" # Maximum duration of 4 hours
    require_approval      = false
    require_justification = true
    require_ticket_info   = false
  }
  # allow permanent eligible assignments (instead of requiring an expiry) for both
  #     permanent and eligible assignments
  active_assignment_rules {
    expiration_required                = false
    expire_after                       = null
    require_justification              = true
    require_multifactor_authentication = false
    require_ticket_info                = false
  }

  eligible_assignment_rules {
    expiration_required = false
    expire_after        = null
  }

  # notification_rules {
  #   active_assignments {}
  #   eligible_activations {}
  #   eligible_assignments {}
  # }

  depends_on = [
    time_sleep.ecp_deployment_contributor_replication_wait
  ]
}

resource "azuread_privileged_access_group_assignment_schedule" "ecp_deployment_contributor_permission_workload_identity_assignment" {
  # Manages an active assignment to a privileged access group.
  #      service principal of DevOps service connection
  for_each = toset(var.ecp_deployment_entraid_contributor_group_pim_enabled ? ["this"] : [])

  group_id        = azuread_group.ecp_deployment_contributor_permission.object_id
  principal_id    = var.ecp_deployment_contributor_workload_identity_object_id
  assignment_type = "member"

  justification        = "Grant permanent assignment to privileged group '${azuread_group.ecp_deployment_contributor_permission.display_name}'"
  permanent_assignment = true

  depends_on = [
    azuread_group_role_management_policy.ecp_deployment_contributor_permission_policy
  ]
}

resource "azuread_privileged_access_group_eligibility_schedule" "ecp_deployment_contributor_permission_eligible" {
  # Manages an eligible assignment to a privileged access group.
  for_each = toset(var.ecp_deployment_entraid_contributor_group_pim_enabled ? ["this"] : [])

  group_id        = azuread_group.ecp_deployment_contributor_permission.object_id
  principal_id    = azuread_group.ecp_deployment_contributor_role.object_id
  assignment_type = "member"

  justification = "Grant eligible membership from group '${azuread_group.ecp_deployment_contributor_role.display_name}' to privileged group '${azuread_group.ecp_deployment_contributor_permission.display_name}'"

  permanent_assignment = true

  depends_on = [
    azuread_group_role_management_policy.ecp_deployment_contributor_permission_policy
  ]
}
