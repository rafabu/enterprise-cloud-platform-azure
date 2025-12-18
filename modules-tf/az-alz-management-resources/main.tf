module "alz_management" {
  source  = "Azure/avm-ptn-alz-management/azurerm"
  version = "0.9.0"

  location = var.azure_location

  # === Resource Group ===
  resource_group_creation_enabled = true
  resource_group_name             = data.azurecaf_name.rg.result

  # === Automation Account ===
  automation_account_name                    = data.azurecaf_name.aa.result
  linked_automation_account_creation_enabled = var.linked_automation_account_creation_enabled

  # === Log Analytics Workspace ===
  log_analytics_workspace_creation_enabled  = var.log_analytics_workspace_creation_enabled
  log_analytics_workspace_name              = data.azurecaf_name.log.result
  log_analytics_workspace_retention_in_days = 30
  log_analytics_workspace_sku               = "PerGB2018"

  # === Data Collection Rules ===
  data_collection_rules = {
    change_tracking = {
      # DCR does not (yet) exist in provider DS - just rename the RG one...
      name = local.ama_change_tracking_data_collection_rule_name
    }
    vm_insights = {
      name = local.ama_vm_insights_data_collection_rule_name
    }
    defender_sql = {
      name = local.ama_defender_sqls_data_collection_rule_name
    }
  }

  # === Sentinel ===
  sentinel_onboarding = null

  # === User Assigned Identities ===
  user_assigned_managed_identities = {
    ama = {
      # UAMI does not (yet) exist in provider DS - just rename the RG one...
      name = local.ama_user_assigned_managed_identity_name
    }
  }

  enable_telemetry = false

  tags = var.azure_tags
}
