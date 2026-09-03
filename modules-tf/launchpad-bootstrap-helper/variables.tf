variable "ecp_network_main_ipv4_address_space" {
  type        = string
  description = "The main IPv4 address space for the ECP network"
}

variable "ecp_launchpad_subscription_id" {
  type        = string
  description = "The subscription ID of the ECP launchpad subscription"
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

variable "virtual_network_artefact_names" {
  type        = list(string)
  default     = []
  description = "List of virtualNetwork artefacts that are created"
}

variable "launchpad_backend_type_previous_run" {
  type = map(object({
    backend_type    = string
    apply_timestamp = optional(string)
  }))
  description = "The backend type used in the previous successful run of this module"
  default     = {}
}
