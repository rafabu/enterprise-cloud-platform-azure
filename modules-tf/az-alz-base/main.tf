module "alz" {
  source  = "Azure/avm-ptn-alz/azurerm"
  version = var.avm-ptn-alz_version

  architecture_name = var.ecp_alz_architecture_name
  location          = var.azure_location

  parent_resource_id = var.ecp_azure_root_parent_management_group_id

  subscription_placement = merge(
    # "management" mg is the ONLY one that is ALWAYS required 
    {
      management = {
        subscription_id       = var.ecp_management_subscription_id
        management_group_name = "${var.ecp_environment_name}-mg-ecpa-platform-management"
      }
    },
    var.ecp_launchpad_subscription_id != "00000000-0000-0000-0000-000000000000" ? {
      launchpad = {
        subscription_id       = var.ecp_launchpad_subscription_id
        management_group_name = "${var.ecp_environment_name}-mg-ecpa-platform-launchpad"
      }
    } : {},
    var.ecp_connectivity_subscription_id != "00000000-0000-0000-0000-000000000000" ? {
      connectivity = {
        subscription_id       = var.ecp_connectivity_subscription_id
        management_group_name = "${var.ecp_environment_name}-mg-ecpa-platform-connectivity"
      }
    } : {},
    var.ecp_identity_subscription_id != "00000000-0000-0000-0000-000000000000" ? {
      identity = {
        subscription_id       = var.ecp_identity_subscription_id
        management_group_name = "${var.ecp_environment_name}-mg-ecpa-platform-identity"
      }
    } : {},
    var.ecp_security_subscription_id != "00000000-0000-0000-0000-000000000000" ? {
      security = {
        subscription_id       = var.ecp_security_subscription_id
        management_group_name = "${var.ecp_environment_name}-mg-ecpa-platform-security"
      }
    } : {}
  )

  #   management_group_hierarchy_settings = {
  #     default_management_group_name            = "sandbox"
  #     require_authorisation_for_group_creation = true
  #     update_existing                          = true
  #   }

  policy_default_values = merge(
    try(length(var.alz_management_resource_ids.ama_user_assigned_managed_identity_id), 0) > 0 ? {
      ama_user_assigned_managed_identity_id = jsonencode(
        {
          value = var.alz_management_resource_ids.ama_user_assigned_managed_identity_id
        }
      )
      ama_user_assigned_managed_identity_name = jsonencode(
        {
          value = basename(var.alz_management_resource_ids.ama_user_assigned_managed_identity_id)
        }
      )
    } : {},
    try(length(var.alz_management_resource_ids.ama_vm_insights_data_collection_rule_id), 0) > 0 ? {
      ama_vm_insights_data_collection_rule_id = jsonencode(
        {
          value = var.alz_management_resource_ids.ama_vm_insights_data_collection_rule_id
        }
    ) } : {},
    try(length(var.alz_management_resource_ids.ama_defender_sqls_data_collection_rule_id), 0) > 0 ? {
      ama_mdfc_sql_data_collection_rule_id = jsonencode(
        {
          value = var.alz_management_resource_ids.ama_defender_sqls_data_collection_rule_id
        }
    ) } : {},
    try(length(var.alz_management_resource_ids.ama_change_tracking_data_collection_rule_id), 0) > 0 ? {
      ama_change_tracking_data_collection_rule_id = jsonencode(
        {
          value = var.alz_management_resource_ids.ama_change_tracking_data_collection_rule_id
        }
    ) } : {},
    try(length(var.alz_management_resource_ids.ddos_protection_plan_id), 0) > 0 ? {
      ddos_protection_plan_id = jsonencode(
        {
          value = var.alz_management_resource_ids.ddos_protection_plan_id
        }
    ) } : {},
    try(length(var.alz_management_resource_ids.log_analytics_workspace_id), 0) > 0 ? {
      log_analytics_workspace_id = jsonencode(
        {
          value = var.alz_management_resource_ids.log_analytics_workspace_id
        }
    ) } : {},

    ##### DEV SPECIFIC POLICY OVERRIDES #####
    #      disarm key vault purge protection policy
    try(var.ecp_environment_stage, "") == "dev" ? {
      key_vault_guardrails_purge_protection_missing_effect = jsonencode(
        {
          value = "Audit"
        }
    ) } : {},


    # extension to Deploy-Private-DNS-Zones assignment (see alz_policy_default_values.json in extension library)
    local.policy_default_values_private_dns_zones
  )

  enable_telemetry                     = false
  role_assignment_name_use_random_uuid = true

  # acts as a depends_on workaround, specific to this AVM module
  # dependencies = {
  #   policy_role_assignments = [
  #   ]
  # }
}
