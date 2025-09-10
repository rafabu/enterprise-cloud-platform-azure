variable "ecp_network_main_ipv4_address_space" {
  type        = string
  description = "The main IPv4 address space for the ECP network"
}


variable "ecp_azure_devops_organization_name" {
  type        = string
  description = "name of Azure DevOps organization"
}

variable "ecp_azure_root_parent_management_group_id" {
  type        = string
  description = "ID of parent management group under which the ECP hierarchy for the environment will be created. Recommended: One level below Azure's Root Management Group."
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
