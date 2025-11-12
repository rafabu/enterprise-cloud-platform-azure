variable "ecp_network_main_ipv4_address_space" {
  type        = string
  description = "The main IPv4 address space for the ECP network"
}

variable "ecp_azure_devops_organization_name" {
  type        = string
  description = "name of Azure DevOps organization"
}

variable "ecp_azure_devops_project_name" {
  type        = string
  description = "name of Azure DevOps project for ECP"
}

variable "ecp_azure_root_parent_management_group_id" {
  type        = string
  description = "ID of parent management group under which the ECP hierarchy for the environment will be created. Recommended: One level below Azure's Root Management Group."
}

variable "ecp_configuration_repo" {
  type        = string
  description = "URL of the Git repository containing the ECP configuration for this environment."
}

variable "ecp_configuration_repo_version" {
  type        = string
  default = "main"
  description = "Version (git tag) of the Git repository containing the ECP configuration for this environment."
}

variable "ecp_configuration_repo_deployment_root_path" {
  type        = string
  description = "subfolder path within the ecp_configuration_repo where the environment deployment files are located."
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

variable "virtual_network_id" {
  # e.g. output of launchpad-network module
  type        = string
  description = "Id of virtualNetwork"
}

variable "virtual_network_subnet_definitions" {
  type = map(object({
    artefactName          = string
    name                  = optional(string)
    addressPrefixes       = optional(list(string))
    defaultOutboundAccess = optional(bool)
    # delegations : optional(list(object({

    # })))
    virtualNetwork : object({
      artefactName = string
    })
    baseAddressOffsets = optional(list(object({
      netnum  = number
      newbits = number
    })))
    privateEndpointNetworkPolicies    = optional(string)
    privateLinkServiceNetworkPolicies = optional(string)
  }))
  description = "Map of virtual network artefacts (virtualNetwork), where the key is the artefactName and the value is an object containing properties of the virtual network."
}

variable "subnet_artefact_names" {
  type        = list(string)
  default     = []
  description = "List of virtualNetwork/subnet artefacts that are created"
}

variable "workload_identity_type" {
  type        = string
  default     = "userAssignedIdentity"
  description = "ADO pool identity type: userAssignedIdentity or serviceprincipal. Defaults to userAssignedIdentity."
  validation {
    condition     = contains(["serviceprincipal", "userAssignedIdentity"], var.workload_identity_type)
    error_message = "variable workload_identity_type must be either 'serviceprincipal' or 'userAssignedIdentity'."
  }
}

variable "dev_center_project_resource_id" {
  type        = string
  description = "(Required) The resource ID of the Dev Center project."
  nullable    = false
}

variable "backend_storage_accounts" {
  type = map(object({
    id       = string
    name     = string
    location = string
    private_endpoint_blob = optional(object({
      fqdn               = string
      private_ip_address = string
    }))
    ecp_level = string
    tf_backend_container = string
  }))
  description = "Map of storage accounts created for each ECP deployment level, with information required for private endpoint access without DNS"
}
