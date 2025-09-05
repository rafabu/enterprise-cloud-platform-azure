variable "ecp_network_main_ipv4_address_space" {
  type        = string
  description = "The main IPv4 address space for the ECP network"
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
    privateEndpointNetworkPolicies    = optional(string)
    privateLinkServiceNetworkPolicies = optional(string)
  }))
  description = "Map of virtual network artefacts (virtualNetwork), where the key is the artefactName and the value is an object containing properties of the virtual network."
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
