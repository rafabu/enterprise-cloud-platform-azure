locals {
  subscription_id     = var.ecp_management_subscription_id
  resource_group_name = data.azurecaf_name.rg.result

  # connectivity (Private DNS Zones)
  subscription_id_connectivity     = var.ecp_connectivity_subscription_id != "00000000-0000-0000-0000-000000000000" ? var.ecp_connectivity_subscription_id : var.ecp_management_subscription_id
  resource_group_name_connectivity = replace(local.resource_group_name, "-mgmt", "-conn")

  log_analytics_workspace_id = provider::azapi::resource_group_resource_id(
    local.subscription_id,
    local.resource_group_name,
    "Microsoft.OperationalInsights/workspaces",
    [
      data.azurecaf_name.log.result
    ]
  )

  ama_change_tracking_data_collection_rule_name = format("%s-%s", replace(data.azurecaf_name.rg.result, "-rg-", "-dcr-"), "change-tracking")
  ama_change_tracking_data_collection_rule_id = provider::azapi::resource_group_resource_id(
    local.subscription_id,
    local.resource_group_name,
    "Microsoft.Insights/dataCollectionRules",
    [
      local.ama_change_tracking_data_collection_rule_name
    ]
  )

  ama_vm_insights_data_collection_rule_name = format("%s-%s", replace(data.azurecaf_name.rg.result, "-rg-", "-dcr-"), "vm-insights")
  ama_vm_insights_data_collection_rule_id = provider::azapi::resource_group_resource_id(
    local.subscription_id,
    local.resource_group_name,
    "Microsoft.Insights/dataCollectionRules",
    [
      local.ama_vm_insights_data_collection_rule_name
    ]
  )

  ama_defender_sqls_data_collection_rule_name = format("%s-%s", replace(data.azurecaf_name.rg.result, "-rg-", "-dcr-"), "defender-sql")
  ama_defender_sqls_data_collection_rule_id = provider::azapi::resource_group_resource_id(
    local.subscription_id,
    local.resource_group_name,
    "Microsoft.Insights/dataCollectionRules",
    [
      local.ama_defender_sqls_data_collection_rule_name
    ]
  )

  ama_user_assigned_managed_identity_name = data.azurecaf_name.rg.result != null ? format("%s-%s", replace(data.azurecaf_name.rg.result, "-rg-", "-id-"), "ama") : null
  ama_user_assigned_managed_identity_id = provider::azapi::resource_group_resource_id(
    local.subscription_id,
    local.resource_group_name,
    "Microsoft.ManagedIdentity/userAssignedIdentities",
    [
      local.ama_user_assigned_managed_identity_name
    ]
  )
}

module "alz_management" {
  source  = "Azure/avm-ptn-alz-management/azurerm"
  version = "0.9.0"

  location = var.azure_location

  # === Resource Group ===
  resource_group_creation_enabled = true
  resource_group_name             = data.azurecaf_name.rg.result

  # === Automation Account ===
  automation_account_name                    = data.azurecaf_name.aa.result
  linked_automation_account_creation_enabled = false

  # === Log Analytics Workspace ===
  log_analytics_workspace_creation_enabled  = true
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


module "alz" {
  source  = "Azure/avm-ptn-alz/azurerm"
  version = "0.15.0"

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
    {
      ama_user_assigned_managed_identity_id = jsonencode(
        {
          value = local.ama_user_assigned_managed_identity_id
        }
      )
      ama_user_assigned_managed_identity_name = jsonencode(
        {
          value = local.ama_user_assigned_managed_identity_name
        }
      )
      ama_vm_insights_data_collection_rule_id = jsonencode(
        {
          value = local.ama_vm_insights_data_collection_rule_id
        }
      )
      ama_mdfc_sql_data_collection_rule_id = jsonencode(
        {
          value = local.ama_defender_sqls_data_collection_rule_id
        }
      )
      ama_change_tracking_data_collection_rule_id = jsonencode(
        {
          value = local.ama_change_tracking_data_collection_rule_id
        }
      )
      # ddos_protection_plan_id = null
      log_analytics_workspace_id = jsonencode(
        {
          value = local.log_analytics_workspace_id
        }
      )
    },
    # extension to Deploy-Private-DNS-Zones assignment (see alz_policy_default_values.json in extension library)
    local.policy_default_values_private_dns_zones
  )
  # private_dns_zone_id_azure_storage_blob = jsonencode(
  # {
  #   value = provider::azapi::resource_group_resource_id(
  #     local.subscription_id_connectivity,
  #     local.resource_group_name_connectivity,
  #     "Microsoft.Network/privateDnsZones",
  #     [
  #       "privatelink.blob.core.windows.net"
  #     ]
  #   )
  # }


  enable_telemetry                     = false
  role_assignment_name_use_random_uuid = true

  # acts as a depends_on workaround, specific to this AVM module
  # dependencies = {
  #   policy_role_assignments = [
  #     module.alz_management.resource_id
  #   ]
  # }

  depends_on = [
    data.external.alz_library_artefact_templating
  ]
}
