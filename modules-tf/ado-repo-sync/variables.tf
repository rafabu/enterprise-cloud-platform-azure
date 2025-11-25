
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

variable "template_replacements" {
  type = map(object({
    file_patterns        = optional(list(string), []) # Glob patterns for files to process
    directory_patterns   = optional(list(string), []) # Glob patterns for directories to rename
    content_replacements = optional(map(string), {})  # Key-value pairs for content replacements
    name_replacements    = optional(map(string), {})  # Key-value pairs for file/directory name replacements
    use_regex            = optional(bool, false)      # Use regex for search patterns
  }))
  description = "Template replacement configurations supporting both content and name replacements"
  default = {
    "ecp_environment_replacement" = {
      directory_patterns = [
        "**/pipelines-ado"
      ]
      name_replacements = {
        "pipelines-ado" = "pipelines-rabu-d7-ado"
      }
      file_patterns = [
        "**/ecp-tg-deploy-platform.yaml"
      ]
      content_replacements = {
        "<ecp_environment_name>" = "rabu-d7"
      }
    }
  }

  # Example:
  # {
  #   "config_transformation" = {
  #     file_patterns = ["**/*.yaml", "**/*.yml"]
  #     directory_patterns = ["**/templates-*", "**/config-*"]
  #     content_replacements = {
  #       "{{ORGANIZATION}}" = "my-org"
  #       "(?i)^<ECP_ARTEFACT>:(.+)"      = "my-project"
  #     }
  #     name_replacements = {
  #       "template-dev"  = "template-prod"
  #       "config-dev"    = "config-prod"
  #       "{{ENV}}"       = "production"
  #     }
  #     use_regex = true
  #   }
  # }
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
