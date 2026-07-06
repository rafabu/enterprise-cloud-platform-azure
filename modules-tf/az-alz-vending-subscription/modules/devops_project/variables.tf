variable "azure_devops_project_name" {
  type        = string
  description = "Name of the Azure DevOps project to create."
}

variable "azure_devops_project_description" {
  type        = string
  default     = ""
  description = "Description of the Azure DevOps project to create."
}
