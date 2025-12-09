variable "ecp_environment_name" {
  type        = string
  description = "Name of the ECP environment (used for naming resources)"
}

variable "ecp_azure_root_parent_management_group_id" {
  type        = string
  description = "The management group ID of the root parent management group for the ECP environment"
}

variable "azure_location" {
  type = string
}

variable "azure_resource_name_elements" {
  type = object({
    prefixes      = optional(list(string))
    suffixes      = optional(list(string))
    name          = optional(string)
    random_length = optional(number)
  })
  description = "Object containing naming components to be used by the azurecaf_name data source to generate resource names."
}

variable "azure_tags" {
  type    = map(string)
  default = {}
}

variable "ecp_deployment_entraid_contributor_group_member_principal_ids" {
  type        = list(string)
  default     = []
  description = "Object IDs of members to be added to the contributor role group. If PIM-enabled, must only be users. Otherwise could be groups, service principals and users."
}

variable "ecp_deployment_entraid_contributor_group_pim_enabled" {
  type        = bool
  default     = true
  description = "Enable or disable PIM for contributor roles (Entra ID groups) in the ECP deployment."
}

variable "ecp_deployment_entraid_contributor_groups_protected" {
  type        = bool
  default     = true
  description = "Enable or disable the Entra ID protected group feature for the ECP environment (groups are role-enabled and have additional security features applied)."
}

variable "ecp_deployment_contributor_workload_identity_object_id" {
  type        = string
  description = "Object ID of the workload identity (user or service principal) used to perform operations in the ECP deployment."
}

variable "ecp_deployment_entraid_reader_group_member_principal_ids" {
  type        = list(string)
  default     = []
  description = "Object IDs of members to be added to the reader role group. If PIM-enabled, must only be users. Otherwise could be groups, service principals and users."
}

variable "ecp_deployment_entraid_reader_group_pim_enabled" {
  type        = bool
  default     = false
  description = "Enable or disable PIM for reader roles (Entra ID groups) in the ECP deployment."
}

variable "ecp_deployment_entraid_reader_groups_protected" {
  type        = bool
  default     = false
  description = "Enable or disable the Entra ID protected group feature for the ECP environment (groups are role-enabled and have additional security features applied)."
}

variable "ecp_deployment_reader_workload_identity_object_id" {
  type        = string
  description = "Object ID of the workload identity (user or service principal) used to perform operations in the ECP deployment."
}

variable "ecp_launchpad_subscription_id" {
  type        = string
  description = "The identifier of the Azure Subscription. (e.g '00000000-0000-0000-0000-000000000000')"
  default = "00000000-0000-0000-0000-000000000000"
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.ecp_launchpad_subscription_id))
    error_message = "The subscription ID must be a valid GUID in the format '00000000-0000-0000-0000-000000000000'."
  }
}

variable "ecp_management_subscription_id" {
  type        = string
  description = "The identifier of the Azure Subscription. (e.g '00000000-0000-0000-0000-000000000000')"
  default = "00000000-0000-0000-0000-000000000000"
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.ecp_management_subscription_id))
    error_message = "The subscription ID must be a valid GUID in the format '00000000-0000-0000-0000-000000000000'."
  }
}

variable "ecp_connectivity_subscription_id" {
  type        = string
  description = "The identifier of the Azure Subscription. (e.g '00000000-0000-0000-0000-000000000000')"
  default = "00000000-0000-0000-0000-000000000000"
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.ecp_connectivity_subscription_id))
    error_message = "The subscription ID must be a valid GUID in the format '00000000-0000-0000-0000-000000000000'."
  }
}

variable "ecp_identity_subscription_id" {
  type        = string
  description = "The identifier of the Azure Subscription. (e.g '00000000-0000-0000-0000-000000000000')"
  default = "00000000-0000-0000-0000-000000000000"
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.ecp_identity_subscription_id))
    error_message = "The subscription ID must be a valid GUID in the format '00000000-0000-0000-0000-000000000000'."
  }
}

variable "ecp_security_subscription_id" {
  type        = string
  description = "The identifier of the Azure Subscription. (e.g '00000000-0000-0000-0000-000000000000')"
  default = "00000000-0000-0000-0000-000000000000"
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.ecp_security_subscription_id))
    error_message = "The subscription ID must be a valid GUID in the format '00000000-0000-0000-0000-000000000000'."
  }
}