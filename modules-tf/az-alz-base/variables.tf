variable "azure_location" {
  type        = string
  description = "Default region for resources deployed into this subscription."
}

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

variable "ecp_alz_avm_version" {
    type = string
    default = "0.15.0"
    description = "Version of the AVM PTN ALZ module 'avm-ptn-alz' to use. See https://github.com/Azure/terraform-azurerm-avm-ptn-alz/releases for available versions."
}

variable "ecp_alz_architecture_name" {
    type        = string
    default     = "ecp-alz-v1"
    description = "The architecture name for the ALZ deployment."
}

variable "alz_library_path_shared" {
    type        = string
    description = "Path to the shared ALZ library artefacts."
}

variable "alz_library_path_unit" {
    type        = string
    description = "Path to the unit's ALZ library artefacts."
}

variable "alz_library_path_shared_rendered" {
    type = string
    description = "Path to the rendered shared ALZ library artefacts."
    default = "./not-set"
}

variable "alz_library_terraform_template_file_name" {
    type        = object({
        match_pattern       = string
        name_remove_string  = string
    })
    default = {
      match_pattern = "**.tftemplate.json"
      name_remove_string = ".tftemplate"
    }
    description = "Pattern to match Terraform template files in the unit's ALZ library artefacts."
}