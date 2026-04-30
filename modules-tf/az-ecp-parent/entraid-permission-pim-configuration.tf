###################### CONTRIBUTOR GROUPS ######################

resource "time_sleep" "contributor_replication_wait" {
  for_each = toset(var.ecp_deployment_entraid_contributor_group_pim_enabled ? ["this"] : [])

  depends_on = [
    azuread_group_without_members.contributor_role,
    azuread_group_without_members.contributor_permission
  ]

  create_duration = "30s"

  lifecycle {
    replace_triggered_by = [
      azuread_group_without_members.contributor_role,
      azuread_group_without_members.contributor_permission
    ]
  }
}

# PIM policy (for the group)
resource "azuread_group_role_management_policy" "contributor_member_policy" {
  for_each = toset(var.ecp_deployment_entraid_contributor_group_pim_enabled ? ["this"] : [])

  group_id = azuread_group_without_members.contributor_permission.object_id
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
    time_sleep.contributor_replication_wait
  ]
}

resource "azuread_group_role_management_policy" "contributor_owner_policy" {
  for_each = toset(var.ecp_deployment_entraid_contributor_group_pim_enabled ? ["this"] : [])

  group_id = azuread_group_without_members.contributor_permission.object_id
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
    expire_after                       = "P365D" # needs a value or expiration_required isn't accepted as false on first deploy
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
    time_sleep.contributor_replication_wait
  ]
}

resource "time_sleep" "contributor_policy_wait" {
  for_each = toset(var.ecp_deployment_entraid_contributor_group_pim_enabled ? ["this"] : [])

  depends_on = [
    azuread_group_role_management_policy.contributor_member_policy,
    azuread_group_role_management_policy.contributor_owner_policy
  ]

  create_duration = "30s"

  lifecycle {
    replace_triggered_by = [
      azuread_group_role_management_policy.contributor_member_policy,
      azuread_group_role_management_policy.contributor_owner_policy
    ]
  }
}

# workload identity ---> permanent member of privileged group
resource "azuread_privileged_access_group_assignment_schedule" "contributor_member_workload_identity_assignment" {
  # Manages an active assignment to a privileged access group.
  #      service principal of DevOps service connection
  for_each = toset(var.ecp_deployment_entraid_contributor_group_pim_enabled ? ["this"] : [])

  group_id        = azuread_group_without_members.contributor_permission.object_id
  principal_id    = var.ecp_deployment_contributor_workload_identity_object_id
  assignment_type = "member"

  justification        = "Grant permanent assignment to privileged group '${azuread_group_without_members.contributor_permission.display_name}'"
  permanent_assignment = true

 lifecycle {
    ignore_changes = [
      justification # MacOS seems to add weird characters that cannot be updated later
    ]
  }

  depends_on = [
    time_sleep.contributor_policy_wait
  ]
}

# workload identity ---> permanent owner of privileged group
resource "azuread_privileged_access_group_assignment_schedule" "contributor_owner_workload_identity_assignment" {
  for_each = toset(var.ecp_deployment_entraid_contributor_group_pim_enabled ? ["this"] : [])

  group_id        = azuread_group_without_members.contributor_permission.object_id
  principal_id    = var.ecp_deployment_contributor_workload_identity_object_id
  assignment_type = "owner"

  justification        = "Grant permanent ownership of privileged group '${azuread_group_without_members.contributor_permission.display_name}'"
  permanent_assignment = true

lifecycle {
    ignore_changes = [
      justification # MacOS seems to add weird characters that cannot be updated later
    ]
  }

  depends_on = [
    time_sleep.contributor_policy_wait
  ]
}

# role group ---> permanently schedule eligible
resource "azuread_privileged_access_group_eligibility_schedule" "contributor_member_eligible" {
  # Manages an eligible assignment to a privileged access group.
  for_each = toset(var.ecp_deployment_entraid_contributor_group_pim_enabled ? ["this"] : [])

  group_id        = azuread_group_without_members.contributor_permission.object_id
  principal_id    = azuread_group_without_members.contributor_role.object_id
  assignment_type = "member"

  justification        = "Grant eligible membership from group '${azuread_group_without_members.contributor_role.display_name}' to privileged group '${azuread_group_without_members.contributor_permission.display_name}'"
  permanent_assignment = true

lifecycle {
    ignore_changes = [
      justification # MacOS seems to add weird characters that cannot be updated later
    ]
  }

  depends_on = [
    time_sleep.contributor_policy_wait
  ]
}

###################### READER GROUPS ######################

resource "time_sleep" "reader_replication_wait" {
  for_each = toset(var.ecp_deployment_entraid_reader_group_pim_enabled ? ["this"] : [])

  depends_on = [
    azuread_group_without_members.reader_role,
    azuread_group_without_members.reader_permission
  ]

  create_duration = "30s"

  lifecycle {
    replace_triggered_by = [
      azuread_group_without_members.reader_role,
      azuread_group_without_members.reader_permission
    ]
  }
}

# PIM policy (for the group)
resource "azuread_group_role_management_policy" "reader_member_policy" {
  for_each = toset(var.ecp_deployment_entraid_reader_group_pim_enabled ? ["this"] : [])

  group_id = azuread_group_without_members.reader_permission.object_id
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
    time_sleep.reader_replication_wait
  ]
}

resource "azuread_group_role_management_policy" "reader_owner_policy" {
  for_each = toset(var.ecp_deployment_entraid_reader_group_pim_enabled ? ["this"] : [])

  group_id = azuread_group_without_members.reader_permission.object_id
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
    expire_after                       = "P365D" # needs a value or expiration_required isn't accepted as false on first deploy
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
    time_sleep.reader_replication_wait
  ]
}

resource "time_sleep" "reader_policy_wait" {
  for_each = toset(var.ecp_deployment_entraid_reader_group_pim_enabled ? ["this"] : [])

  depends_on = [
    azuread_group_role_management_policy.reader_member_policy,
    azuread_group_role_management_policy.reader_owner_policy
  ]

  create_duration = "30s"

  lifecycle {
    replace_triggered_by = [
      azuread_group_role_management_policy.reader_member_policy,
      azuread_group_role_management_policy.reader_owner_policy
    ]
  }
}

# workload identity ---> permanent member of privileged group
resource "azuread_privileged_access_group_assignment_schedule" "reader_member_workload_identity_assignment" {
  # Manages an active assignment to a privileged access group.
  #      service principal of DevOps service connection
  for_each = toset(var.ecp_deployment_entraid_reader_group_pim_enabled ? ["this"] : [])

  group_id        = azuread_group_without_members.reader_permission.object_id
  principal_id    = var.ecp_deployment_reader_workload_identity_object_id
  assignment_type = "member"

  justification        = "Grant permanent assignment to privileged group '${azuread_group_without_members.reader_permission.display_name}'"
  permanent_assignment = true

  depends_on = [
    time_sleep.reader_policy_wait
  ]
}

# workload identity ---> permanent owner of privileged group
resource "azuread_privileged_access_group_assignment_schedule" "reader_owner_workload_identity_assignment" {
  for_each = toset(var.ecp_deployment_entraid_reader_group_pim_enabled ? ["this"] : [])

  group_id        = azuread_group_without_members.reader_permission.object_id
  principal_id    = var.ecp_deployment_contributor_workload_identity_object_id # owner must be the CONTRIBUTOR
  assignment_type = "owner"

  justification        = "Grant permanent ownership of privileged group '${azuread_group_without_members.reader_permission.display_name}'"
  permanent_assignment = true

  depends_on = [
    time_sleep.reader_policy_wait
  ]
}

# role group ---> permanently schedule eligible
resource "azuread_privileged_access_group_eligibility_schedule" "reader_member_eligible" {
  # Manages an eligible assignment to a privileged access group.
  for_each = toset(var.ecp_deployment_entraid_reader_group_pim_enabled ? ["this"] : [])

  group_id        = azuread_group_without_members.reader_permission.object_id
  principal_id    = azuread_group_without_members.reader_role.object_id
  assignment_type = "member"

  justification        = "Grant eligible membership from group '${azuread_group_without_members.reader_role.display_name}' to privileged group '${azuread_group_without_members.reader_permission.display_name}'"
  permanent_assignment = true

  depends_on = [
    time_sleep.reader_policy_wait
  ]
}
