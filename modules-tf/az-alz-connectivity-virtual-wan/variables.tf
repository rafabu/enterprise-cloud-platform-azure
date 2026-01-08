variable "azure_location" {
  type        = string
  description = "Default region for resources deployed into this subscription."
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
  type        = map(string)
  description = "A map of tags to assign to the resource."
  default     = {}
}

variable "ecp_launchpad_subscription_id" {
  type        = string
  description = "The identifier of the Azure Subscription. (e.g '00000000-0000-0000-0000-000000000000')"
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.ecp_launchpad_subscription_id))
    error_message = "The subscription ID must be a valid GUID in the format '00000000-0000-0000-0000-000000000000'."
  }
}

variable "ecp_management_subscription_id" {
  type        = string
  description = "The identifier of the Azure Subscription. (e.g '00000000-0000-0000-0000-000000000000')"
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.ecp_management_subscription_id))
    error_message = "The subscription ID must be a valid GUID in the format '00000000-0000-0000-0000-000000000000'."
  }
}

variable "ecp_connectivity_subscription_id" {
  type        = string
  description = "The identifier of the Azure Subscription. (e.g '00000000-0000-0000-0000-000000000000')"
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.ecp_connectivity_subscription_id))
    error_message = "The subscription ID must be a valid GUID in the format '00000000-0000-0000-0000-000000000000'."
  }
}


variable "ecp_network_main_ipv4_address_space" {
  type        = string
  description = "The main IPv4 address space for the ECP network"
}

# vWan hubs
variable "virtual_wan_hubs" {
  type = map(object({
    location                     = optional(string, null)
    address_prefix_artefact_name = string

    sku                                    = optional(string, null)
    hub_routing_preference                 = optional(string, "ExpressRoute")
    virtual_router_auto_scale_min_capacity = optional(number, 2)
    tags                                   = optional(map(string))
  }))
  description = "A map of Virtual WAN hubs to create."
  default     = {}
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
}

variable "virtual_network_artefact_names" {
  type        = list(string)
  default     = []
  description = "List of virtualNetwork artefacts that are created"
}
