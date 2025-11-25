variable "ecp_environment_name" {
  type        = string
  description = "Name of the ECP environment (used for naming resources)"
}

variable "ecp_azure_devops_organization_name" {
  type        = string
  description = "name of Azure DevOps organization"
}

variable "ecp_azure_devops_project_name" {
  type        = string
  description = "Name of Azure DevOps project for ECP"
}

variable "ecp_azure_devops_repository_name" {
  type        = string
  description = "Name of Azure DevOps repository for ECP"
}

variable "ado_yaml_pipeline_definitions" {
  # https://learn.microsoft.com/en-us/rest/api/azure/devops/build/definitions/create?view=azure-devops-rest-7.1
  type = map(object({
    artefactName = string
    nameElement  = optional(string)

    path       = optional(string)
    branchName = optional(string)
    process = object({
      yamlFilename = string
    })
    project = optional(object({
      name = optional(string)
      id   = optional(string)
    }))
    queue = object({
      name = string
    })
    queueStatus = optional(string) # paused or disabled
    repository = object({
      name               = optional(string)
      id                 = optional(string)
      type               = optional(string)
      defaultBranch      = optional(string)
      checkoutSubmodules = optional(bool)
      properties = optional(object({
        reportBuildStatus = bool
      }))
    })
    skipFirstRun          = optional(bool)
    jobAuthorizationScope = optional(string)

  }))
  description = "Map of Azure DevOps Pipelines (pipelines), where the key is the artefactName and the value is an object containing properties of the pipeline."
}

variable "ado_yaml_pipeline_artefact_names" {
  type = list(string)
  # default     = []
  description = "List of Azure DevOps pipeline artefacts that are created"
}
