locals {
  subscription_id_management = var.ecp_management_subscription_id
  resource_group_name        = data.azurecaf_name.rg.result

  # connectivity (Private DNS Zones)
  subscription_id_connectivity     = var.ecp_connectivity_subscription_id != "00000000-0000-0000-0000-000000000000" ? var.ecp_connectivity_subscription_id : var.ecp_management_subscription_id
  resource_group_name_connectivity = replace(local.resource_group_name, "-mgmt", "-conn")

  resource_group_id = provider::azapi::subscription_resource_id(
    local.subscription_id_management,
    "Microsoft.Resources/resourceGroups",
    [
      local.resource_group_name
    ]
  )

  automation_account_id = provider::azapi::resource_group_resource_id(
    local.subscription_id_management,
    local.resource_group_name,
    "Microsoft.OperationalInsights/workspaces",
    [
      data.azurecaf_name.aa.result
    ]
  )

  log_analytics_workspace_id = provider::azapi::resource_group_resource_id(
    local.subscription_id_management,
    local.resource_group_name,
    "Microsoft.OperationalInsights/workspaces",
    [
      data.azurecaf_name.log.result
    ]
  )

  ama_change_tracking_data_collection_rule_name = format("%s-%s", replace(data.azurecaf_name.rg.result, "-rg-", "-dcr-"), "change-tracking")
  ama_change_tracking_data_collection_rule_id = provider::azapi::resource_group_resource_id(
    local.subscription_id_management,
    local.resource_group_name,
    "Microsoft.Insights/dataCollectionRules",
    [
      local.ama_change_tracking_data_collection_rule_name
    ]
  )

  ama_vm_insights_data_collection_rule_name = format("%s-%s", replace(data.azurecaf_name.rg.result, "-rg-", "-dcr-"), "vm-insights")
  ama_vm_insights_data_collection_rule_id = provider::azapi::resource_group_resource_id(
    local.subscription_id_management,
    local.resource_group_name,
    "Microsoft.Insights/dataCollectionRules",
    [
      local.ama_vm_insights_data_collection_rule_name
    ]
  )

  ama_defender_sqls_data_collection_rule_name = format("%s-%s", replace(data.azurecaf_name.rg.result, "-rg-", "-dcr-"), "defender-sql")
  ama_defender_sqls_data_collection_rule_id = provider::azapi::resource_group_resource_id(
    local.subscription_id_management,
    local.resource_group_name,
    "Microsoft.Insights/dataCollectionRules",
    [
      local.ama_defender_sqls_data_collection_rule_name
    ]
  )

  ama_user_assigned_managed_identity_name = data.azurecaf_name.rg.result != null ? format("%s-%s", replace(data.azurecaf_name.rg.result, "-rg-", "-id-"), "ama") : null
  ama_user_assigned_managed_identity_id = provider::azapi::resource_group_resource_id(
    local.subscription_id_management,
    local.resource_group_name,
    "Microsoft.ManagedIdentity/userAssignedIdentities",
    [
      local.ama_user_assigned_managed_identity_name
    ]
  )
}
