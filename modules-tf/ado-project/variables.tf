variable "ecp_azure_devops_organization_name" {
  type        = string
  description = "name of Azure DevOps organization"
}

variable "ecp_azure_devops_project_name" {
  type        = string
  description = "name of Azure DevOps project for ECP"
}

# variable "ecp_azure_devops_repository_name" {
#   type        = string
#   description = "name of Azure DevOps repository for ECP"
# }

variable "ecp_azure_devops_repository_names" {
  type        = list(string)
  default     = []
  description = "names of Azure DevOps repositories for ECP"
}
