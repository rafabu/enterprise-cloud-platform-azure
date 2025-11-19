variable "azure_resource_name_elements" {
  type = object({
    prefixes      = optional(list(string))
    suffixes      = optional(list(string))
    name          = optional(string)
    random_length = optional(number)
  })
  description = "Object containing naming components to be used by the azurecaf_name data source to generate resource names."
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
    path    = optional(string)

    yamlFilename       = string
    skipFirstRun      = optional(bool)
    
  }))
  description = "Map of Azure DevOps Pipelines (pipelines), where the key is the artefactName and the value is an object containing properties of the pipeline."

default = {
    ecp-l0-launchpad-pipeline = {
      artefactName  = "ecp-l0-launchpad-pipeline"
      nameElement   = "ECP L0 Launchpad Pipeline"
      yamlFilename  = "/pipelines-ado/ecp-l0-launchpad.yaml"
      skipFirstRun = true
    }
  }
}


variable "ado_yaml_pipeline_names" {
  type        = list(string)
  # default     = []
  description = "List of Azure DevOps pipeline artefacts that are created"
  default = [
    "ecp-l0-launchpad-pipeline"
  ]
}
