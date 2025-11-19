variable "ecp_azure_devops_organization_name" {
  type        = string
  description = "Name of Azure DevOps organization"
}

variable "ecp_azure_devops_project_name" {
  type        = string
  description = "Name of Azure DevOps project for ECP"
}

variable "ecp_azure_devops_repository_name" {
  type        = string
  description = "Name of Azure DevOps repository for ECP"
}

variable "ecp_azure_devops_target_branch" {
  type        = string
  description = "Target branch in Azure DevOps repository"
  default     = "main"
}

variable "local_git_submodule_path" {
  type        = string
  description = "Path to local submodule directory relative to module root"
}

variable "sync_enabled" {
  type        = bool
  description = "Enable or disable repository synchronization"
  default     = true
}

variable "force_sync" {
  type        = bool
  description = "Force synchronization even if no changes detected"
  default     = false
}
