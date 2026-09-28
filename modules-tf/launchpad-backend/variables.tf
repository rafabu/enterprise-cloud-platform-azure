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

variable "ecp_automation_terragrunt_version" {
  type        = string
  description = "Version of Terragrunt used for ECP automation (use this for pinning)"
  default     = "latest"
}

variable "ecp_automation_terraform_version" {
  type        = string
  description = "Version of Terraform used for ECP automation (use this for pinning)"
  default     = "latest"
}

variable "ecp_network_main_ipv4_address_space" {
  type        = string
  description = "The main IPv4 address space for the ECP network"
}

variable "azure_location" {
  type        = string
  description = "The Azure location where resources will be deployed"
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

variable "virtual_network_definitions" {
  # https://learn.microsoft.com/en-us/graph/api/resources/countrynamedlocation?view=graph-rest-1.0
  type = map(object({
    artefactName = string
    nameElement  = optional(string)
    addressSpace = object({
      addressPrefixes = optional(list(string))
      baseAddressOffsets = optional(list(object({
        netnum  = number
        newbits = number
      })))
    })
    dhcpOptions = optional(object({
      dnsServers = optional(list(string))
    }))
    encryption = optional(object({
      enabled     = bool
      enforcement = string
    }))
    privateEndpointVNetPolicies = optional(string)
  }))
  description = "Map of virtual network artefacts (virtualNetwork), where the key is the artefactName and the value is an object containing properties of the virtual network."

  validation {
    condition = alltrue([
      for subnet in var.virtual_network_definitions :
      subnet.privateEndpointVNetPolicies == null
      || contains([
        "Basic",
        "Disabled"
      ], subnet.privateEndpointVNetPolicies)
    ])
    error_message = "privateEndpointVNetPolicies must be one of: Basic, Disabled (or omitted)."
  }
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

  validation {
    condition = alltrue([
      for subnet in var.virtual_network_subnet_definitions :
      subnet.privateEndpointNetworkPolicies == null
      || contains([
        "Enabled",
        "NetworkSecurityGroupEnabled",
        "RouteTableEnabled",
        "Disabled"
      ], subnet.privateEndpointNetworkPolicies)
    ])
    error_message = "privateEndpointNetworkPolicies must be one of: Enabled, NetworkSecurityGroupEnabled, RouteTableEnabled, Disabled (or omitted)."
  }

  validation {
    condition = alltrue([
      for subnet in var.virtual_network_subnet_definitions :
      subnet.privateLinkServiceNetworkPolicies == null
      || contains([
        "Enabled",
        "Disabled"
      ], subnet.privateLinkServiceNetworkPolicies)
    ])
    error_message = "privateLinkServiceNetworkPolicies must be one of: Enabled, Disabled (or omitted)."
  }
}

variable "virtual_network_artefact_names" {
  type        = list(string)
  default     = []
  description = "List of virtualNetwork artefacts that are created"
}

variable "subnet_artefact_names" {
  type        = list(string)
  default     = []
  description = "List of virtualNetwork/subnet artefacts that are created"
}

variable "storage_account_public_network_access_enabled" {
  type        = bool
  description = "Whether to allow public network access for the storage account. Default is false."
  default     = false
}
