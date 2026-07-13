##################################################    Entra ID Groups    ##################################################
# Role
resource "azuread_group" "role" {
  # PIM-able (privileged) group takes naming of permission group
  display_name            = var.role_display_name
  prevent_duplicate_names = true
  security_enabled        = true
  assignable_to_role      = var.use_pim

  members = var.use_pim ? [] : var.role_member_object_ids
  owners = var.use_pim ? [var.vending_managed_identity_object_id] : distinct(concat(
    [var.vending_managed_identity_object_id],
    var.role_owner_object_ids
  ))

  lifecycle {
    ignore_changes = [
      members
    ]
  }

}

#Permission
resource "azuread_group" "permission" {
  display_name = var.permission_display_name
  # Error: could not check for existing group(s): unable to list Groups with filter "displayName eq '*****************'": the context used must have a deadline attached for polling purposes, but got no deadline
  prevent_duplicate_names = true
  security_enabled        = true

  members = distinct(concat(
    [
      azuread_group.role.object_id,
    ],
    var.use_pim ? [] : var.permanent_permission_member_object_ids
  ))
  owners = [
    var.vending_managed_identity_object_id
  ]

  lifecycle {
    ignore_changes = [
      owners
    ]
  }
}

################################
# Privileged Identity Management
################################
# Eligible Principals Group
resource "azuread_group" "role_eligible" {
  for_each = toset(var.use_pim ? ["this"] : [])

  display_name = var.role_eligible_display_name

  prevent_duplicate_names = true
  security_enabled        = true
  assignable_to_role      = var.use_pim

  members = var.role_member_object_ids
  owners = distinct(concat(
    [var.vending_managed_identity_object_id],
    var.role_owner_object_ids
  ))

  lifecycle {
    ignore_changes = [
      members
    ]
  }
}

##################################################    PIM Policy & Schedules   ##################################################
# Configure PIM eligibility policy for the group
resource "time_sleep" "replication_wait" {
  for_each = toset(var.use_pim ? ["this"] : [])

  depends_on = [
    azuread_group.role,
    azuread_group.role_eligible
  ]

  create_duration = "120s" # entra replication delay
}

resource "azuread_group_role_management_policy" "role_member_policy" {
  for_each = toset(var.use_pim ? ["this"] : [])

  group_id = azuread_group.role.object_id
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

  group_id = azuread_group.role.object_id
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
  for_each = toset(length(var.permanent_permission_member_object_ids) > 0 && var.use_pim ? var.permanent_permission_member_object_ids : [])

  group_id        = azuread_group.role.object_id
  principal_id    = each.key
  assignment_type = "member"

  justification = "Grant permanent assignment to privileged group '${azuread_group.role.display_name}'"

  permanent_assignment = true

  lifecycle {
    ignore_changes = [justification]
  }

  depends_on = [
    time_sleep.policy_replication_wait
  ]
}

resource "azuread_privileged_access_group_assignment_schedule" "role_owner_assignment" {
  for_each = toset(var.use_pim ? ["this"] : [])

  # ECP deployment principal has to become owner
  group_id        = azuread_group.role.object_id
  principal_id    = var.vending_managed_identity_object_id
  assignment_type = "owner"

  justification = "Grant permanent assignment to privileged group '${azuread_group.role.display_name}'"

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

  group_id        = azuread_group.role.object_id
  principal_id    = azuread_group.role_eligible[each.key].object_id
  assignment_type = "member"

  justification        = "Grant eligible membership from group '${azuread_group.role_eligible[each.key].display_name}' to privileged group '${azuread_group.role.display_name}'"
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
