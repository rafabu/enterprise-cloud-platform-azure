variable "azure_location" {
  type        = string
  description = "Default region for resources deployed into this subscription."
}

# variable "azure_resource_name_elements" {
#   type = object({
#     prefixes      = optional(list(string))
#     suffixes      = optional(list(string))
#     name          = optional(string)
#     random_length = optional(number)
#   })
#   description = "Object containing naming components to be used by the azurecaf_name data source to generate resource names."
# }

# variable "azure_tags" {
#   type    = map(string)
#   default = {}
# }

variable "ecp_environment_name" {
  type        = string
  description = "Name of the ECP environment (used for naming resources)"
}

variable "ecp_azure_root_parent_management_group_id" {
  type        = string
  description = "The management group ID of the parent management group for the ECP environment"
}

variable "alz_parent_management_group_resource_id" {
  type        = string
  description = "The management group resource ID of the management group of this ECP environment"
}

variable "ecp_launchpad_subscription_id" {
  type        = string
  description = "The identifier of the Azure Subscription. (e.g '00000000-0000-0000-0000-000000000000')"
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.ecp_launchpad_subscription_id))
    error_message = "The subscription ID must be a valid GUID in the format '00000000-0000-0000-0000-000000000000'."
  }
}

variable "ecp_management_subscription_id" {
  type        = string
  description = "The identifier of the Azure Subscription. (e.g '00000000-0000-0000-0000-000000000000')"
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.ecp_management_subscription_id))
    error_message = "The subscription ID must be a valid GUID in the format '00000000-0000-0000-0000-000000000000'."
  }
}

variable "ecp_connectivity_subscription_id" {
  type        = string
  description = "The identifier of the Azure Subscription. (e.g '00000000-0000-0000-0000-000000000000')"
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.ecp_connectivity_subscription_id))
    error_message = "The subscription ID must be a valid GUID in the format '00000000-0000-0000-0000-000000000000'."
  }
}

variable "ecp_identity_subscription_id" {
  type        = string
  description = "The identifier of the Azure Subscription. (e.g '00000000-0000-0000-0000-000000000000')"
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.ecp_identity_subscription_id))
    error_message = "The subscription ID must be a valid GUID in the format '00000000-0000-0000-0000-000000000000'."
  }
}

variable "ecp_security_subscription_id" {
  type        = string
  description = "The identifier of the Azure Subscription. (e.g '00000000-0000-0000-0000-000000000000')"
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.ecp_security_subscription_id))
    error_message = "The subscription ID must be a valid GUID in the format '00000000-0000-0000-0000-000000000000'."
  }
}

# variable "ecp_alz_avm_version" {
#     type = string
#     default = "0.15.0"
#     description = "Version of the AVM PTN ALZ module 'avm-ptn-alz' to use. See https://github.com/Azure/terraform-azurerm-avm-ptn-alz/releases for available versions."
# }

variable "ecp_alz_architecture_name" {
  type        = string
  default     = "ecp-alz-v1"
  description = "The architecture name for the ALZ deployment."
}

variable "alz_library_path_shared_rendered" {
  type        = string
  description = "Path to the rendered shared ALZ library artefacts. Used to configure the ALZ provider."
  default     = "./not-set"
}

variable "alz_management_resource_ids" {
  type = object({
    log_analytics_workspace_id                  = optional(string)
    ama_change_tracking_data_collection_rule_id = optional(string)
    ama_vm_insights_data_collection_rule_id     = optional(string)
    ama_defender_sqls_data_collection_rule_id   = optional(string)
    ama_user_assigned_managed_identity_id       = optional(string)
    ddos_protection_plan_id                     = optional(string)
  })
  default = {
    # ama_change_tracking_data_collection_rule_id = "/subscriptions/5c838b6a-9149-423a-9de4-ff1682f70388/resourceGroups/rabu-d7-rg-ecpa-mgmt/providers/Microsoft.Insights/dataCollectionRules/rabu-d7-dcr-ecpa-mgmt-change-tracking"
    # ama_defender_sqls_data_collection_rule_id   = "/subscriptions/5c838b6a-9149-423a-9de4-ff1682f70388/resourceGroups/rabu-d7-rg-ecpa-mgmt/providers/Microsoft.Insights/dataCollectionRules/rabu-d7-dcr-ecpa-mgmt-defender-sql"
    # ama_user_assigned_identity_id               = "/subscriptions/5c838b6a-9149-423a-9de4-ff1682f70388/resourceGroups/rabu-d7-rg-ecpa-mgmt/providers/Microsoft.ManagedIdentity/userAssignedIdentities/rabu-d7-id-ecpa-mgmt-ama"
    # ama_vm_insights_data_collection_rule_id     = "/subscriptions/5c838b6a-9149-423a-9de4-ff1682f70388/resourceGroups/rabu-d7-rg-ecpa-mgmt/providers/Microsoft.Insights/dataCollectionRules/rabu-d7-dcr-ecpa-mgmt-vm-insights"
    # log_analytics_workspace_id                  = "/subscriptions/5c838b6a-9149-423a-9de4-ff1682f70388/resourceGroups/rabu-d7-rg-ecpa-mgmt/providers/Microsoft.OperationalInsights/workspaces/rabu-d7-log-ecpa-mgmt"
    # ddos_protection_plan_id                     = null
  }
  description = "Objects mapping management resource key to resource Id,"
}

variable "private_dns_zone_configuration" {
  type        = map(string)
  default     = {}
  description = "Objects mapping private DNS zone key to resource Id,"
}
