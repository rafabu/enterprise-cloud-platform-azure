variable "ecp_environment_name" {
  type        = string
  description = "Name of the ECP environment (used for naming resources)"
}

variable "ecp_launchpad_subscription_id" {
  type        = string
  description = "The subscription ID of the ECP launchpad subscription"
}


variable "ecp_azure_devops_automation_repository_name" {
  type        = string
  default     = "ECP.Automation"
  description = "Name of the ECP Azure DevOps automation repository"
}

variable "ecp_azure_devops_configuration_repository_name" {
  type        = string
  default     = "ECP.Configuration"
  description = "Name of the ECP Azure DevOps configuration repository"
}

variable "ecp_azure_devops_organization_name" {
  type        = string
  description = "name of Azure DevOps organization"
}

variable "ecp_configuration_repo_deployment_root_path" {
  type        = string
  description = "Root path in ECP.Configuration repository where environment configurations are stored"
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
