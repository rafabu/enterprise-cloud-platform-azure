variable "azure_location" {
  type        = string
  description = "Default region for resources deployed into this subscription."
}

variable "ecp_environment_name" {
  type        = string
  description = "Name of the ECP environment (used for naming resources)"
}

variable "ecp_environment_stage" {
  type        = string
  description = "The stage of the environment in the ECP environment lifecycle (e.g. 'dev', 'test', 'prod')."
  default     = ""
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
  default     = {}
  description = "Objects mapping management resource key to resource Id,"
}

variable "private_dns_zone_configuration" {
  type        = map(string)
  default     = {}
  description = "Objects mapping private DNS zone key to resource Id,"
}
