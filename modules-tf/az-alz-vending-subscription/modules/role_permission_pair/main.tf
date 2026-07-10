data "azuread_client_config" "current" {
}

data "azuread_directory_object" "current" {
  object_id = data.azuread_client_config.current.object_id
}

# resource "terraform_data" "ServicePrincipal" {
#   for_each = toset(var.use_pim ? ["this"] : [])

#   input    = data.azuread_directory_object.current.type

#   lifecycle {
#     precondition {
#       condition     = data.azuread_directory_object.current.type == "ServicePrincipal"
#       error_message = "PIM policy && PIM schedule can only be assigned using a ServicePrincipal (not an interactive account). This is an Azure Resource API restriction."
#     }
#   }
# }

##################################################    Entra ID Groups    ##################################################
# Role
locals {
  role_member_object_ids = distinct(concat(
    [
      "edbed720-059e-4c71-9626-5abced49bc49"
    ],
  var.role_member_object_ids))
}

resource "azuread_group_without_members" "role" {
  # PIM-able (privileged) group takes naming of permission group
  display_name            = var.role_display_name
  prevent_duplicate_names = true
  security_enabled        = true
  assignable_to_role      = var.use_pim

  owners = var.use_pim ? [] : local.role_member_object_ids

  lifecycle {
    ignore_changes = [
      owners
    ]
  }
}

resource "azuread_group_member" "role" {
  # direct membership only if not using PIM
  for_each = toset(var.use_pim == false ? var.role_member_object_ids : [])

  group_object_id  = azuread_group_without_members.role.object_id
  member_object_id = each.key
}

#Permission
resource "azuread_group_without_members" "permission" {
  display_name = var.permission_display_name
  # Error: could not check for existing group(s): unable to list Groups with filter "displayName eq '*****************'": the context used must have a deadline attached for polling purposes, but got no deadline
  prevent_duplicate_names = true
  security_enabled        = true

  owners = [
    data.azuread_client_config.current.object_id
  ]

  lifecycle {
    ignore_changes = [
      owners
    ]
  }
}

resource "azuread_group_member" "permission" {
  group_object_id  = azuread_group_without_members.permission.object_id
  member_object_id = azuread_group_without_members.role.object_id
}

################################
# Privileged Identity Management
################################
# Eligible Principals Group
resource "azuread_group_without_members" "role_eligible" {
  for_each = toset(var.use_pim ? ["this"] : [])

  display_name = var.role_eligible_display_name

  prevent_duplicate_names = true
  security_enabled        = true
  assignable_to_role      = var.use_pim

  owners = [
    data.azuread_client_config.current.object_id
  ]

  lifecycle {
    ignore_changes = [
      owners
    ]
  }
}

# set members of the "eligible" group (users allowed to activate the privileged group membership)
resource "azuread_group_member" "role_eligible" {
  # interactive users only
  for_each = toset(var.use_pim ? var.role_member_object_ids : [])

  group_object_id  = azuread_group_without_members.role_eligible["this"].object_id
  member_object_id = each.key
}

##################################################    PIM Policy & Schedules   ##################################################
# Configure PIM eligibility policy for the group
resource "time_sleep" "replication_wait" {
  for_each = toset(var.use_pim ? ["this"] : [])

  depends_on = [
    azuread_group_without_members.role,
    azuread_group_without_members.role_eligible
  ]

  create_duration = "120s" # entra replication delay
}

resource "azuread_group_role_management_policy" "role_member_policy" {
  for_each = toset(var.use_pim ? ["this"] : [])

  group_id = azuread_group_without_members.role.object_id
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
    expire_after                       = "P365D"
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
    time_sleep.replication_wait
  ]
}

resource "azuread_group_role_management_policy" "role_owner_policy" {
  for_each = toset(var.use_pim ? ["this"] : [])

  group_id = azuread_group_without_members.role.object_id
  role_id  = "owner"

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
    expire_after                       = "P365D"
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
    time_sleep.replication_wait
  ]
}

resource "time_sleep" "policy_replication_wait" {
  for_each = toset(var.use_pim ? ["this"] : [])

  depends_on = [
    azuread_group_role_management_policy.role_member_policy,
    azuread_group_role_management_policy.role_owner_policy
  ]

  create_duration = "120s" # entra replication delay
}

# permanent assignment for service principal (user assigned managed identity)
resource "azuread_privileged_access_group_assignment_schedule" "role_member_assignment" {
  # Manages an active assignment to a privileged access group.
  #      service principal of DevOps service connection
  for_each = toset(length(var.pim_permanent_role_member_object_ids) > 0 && var.use_pim ? var.pim_permanent_role_member_object_ids : [])

  group_id        = azuread_group_without_members.role.object_id
  principal_id    = each.key
  assignment_type = "member"

  justification = "Grant permanent assignment to privileged group '${azuread_group_without_members.role.display_name}'"

  permanent_assignment = true

  lifecycle {
    ignore_changes = [justification]
  }

  depends_on = [
    time_sleep.policy_replication_wait
  ]
}

resource "azuread_privileged_access_group_assignment_schedule" "role_owner_assignment" {
  # Manages an active assignment to a privileged access group.
  #      service principal of DevOps service connection
  for_each = toset(length(var.pim_permanent_role_member_object_ids) > 0 && var.use_pim ? var.pim_permanent_role_member_object_ids : [])

  group_id        = azuread_group_without_members.role.object_id
  principal_id    = each.key
  assignment_type = "owner"

  justification = "Grant permanent assignment to privileged group '${azuread_group_without_members.role.display_name}'"

  permanent_assignment = true

  lifecycle {
    ignore_changes = [justification]
  }

  depends_on = [
    time_sleep.policy_replication_wait
  ]
}

# role group ---> permanently schedule eligible
resource "azuread_privileged_access_group_eligibility_schedule" "role_member_eligible" {
  # Manages an eligible assignment to a privileged access group.
  for_each = toset(var.use_pim ? ["this"] : [])

  group_id        = azuread_group_without_members.role.object_id
  principal_id    = azuread_group_without_members.role_eligible[each.key].object_id
  assignment_type = "member"

  justification        = "Grant eligible membership from group '${azuread_group_without_members.role_eligible[each.key].display_name}' to privileged group '${azuread_group_without_members.role.display_name}'"
  permanent_assignment = true

  lifecycle {
    ignore_changes = [
      justification # MacOS seems to add weird characters that cannot be updated later
    ]
  }

  depends_on = [
    time_sleep.policy_replication_wait
  ]
}
