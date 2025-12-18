# outputs based on static resource IDs in locals.terraform {
#     should help towards a more stable state world :-)
output "automation_account_id" {
  value = var.linked_automation_account_creation_enabled ? local.automation_account_id : null
}

output "resource_group_id" {
  value = local.resource_group_id
}

output "log_analytics_workspace_id" {
  value = var.log_analytics_workspace_creation_enabled ? local.log_analytics_workspace_id : null
}

output "ama_user_assigned_identity_id" {
  value = local.ama_user_assigned_managed_identity_id
}

output "ama_change_tracking_data_collection_rule_id" {
  value = local.ama_change_tracking_data_collection_rule_id
}

output "ama_vm_insights_data_collection_rule_id" {
  value = local.ama_vm_insights_data_collection_rule_id
}

output "ama_defender_sqls_data_collection_rule_id" {
  value = local.ama_defender_sqls_data_collection_rule_id
}
