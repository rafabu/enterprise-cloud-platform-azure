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

variable "ecp_hub_locations" {
  type = map(object({
    azure_location                      = string
    ecp_network_main_ipv4_address_space = string
    is_main_location                    = optional(bool, false)
  }))
  default     = {}
  description = "Regions to deploy ecp hub components to that need geographical dispersion. Note: Setting var.azure_location and var.ecp_network_main_ipv4_address_space overrides a default."
}

variable "virtual_network_artefacts" {
  type = map(object({
    filePath = string
    artefact = optional(object({
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
  }))
  description = "merged virtualNetwork artefacts sourced from library"

  validation {
    condition = alltrue([
      for vnet in var.virtual_network_artefacts :
      vnet.artefact.privateEndpointVNetPolicies == null
      || contains([
        "Basic",
        "Disabled"
      ], vnet.artefact.privateEndpointVNetPolicies)
    ])
    error_message = "privateEndpointVNetPolicies must be one of: Basic, Disabled (or omitted)."
  }
}

variable "virtual_network_subnet_artefacts" {
  type = map(object({
    filePath = string
    artefact = optional(object({
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
  }))
  description = "Map of virtual network artefacts (virtualNetwork), where the key is the artefactName and the value is an object containing properties of the virtual network."

  validation {
    condition = alltrue([
      for subnet in var.virtual_network_subnet_artefacts :
      subnet.artefact.privateEndpointNetworkPolicies == null
      || contains([
        "Enabled",
        "NetworkSecurityGroupEnabled",
        "RouteTableEnabled",
        "Disabled"
      ], subnet.artefact.privateEndpointNetworkPolicies)
    ])
    error_message = "privateEndpointNetworkPolicies must be one of: Enabled, NetworkSecurityGroupEnabled, RouteTableEnabled, Disabled (or omitted)."
  }

  validation {
    condition = alltrue([
      for subnet in var.virtual_network_subnet_artefacts :
      subnet.artefact.privateLinkServiceNetworkPolicies == null
      || contains([
        "Enabled",
        "Disabled"
      ], subnet.artefact.privateLinkServiceNetworkPolicies)
    ])
    error_message = "privateLinkServiceNetworkPolicies must be one of: Enabled, Disabled (or omitted)."
  }
}

variable "vpn_gateway_artefacts" {
  type = map(object({
    filePath = string
    artefact = optional(object({
      artefactName = string
      nameElement  = optional(string)

      location = optional(string)

      bgpSettings = optional(object({
        asn = optional(number, 65515)
        bgpPeeringAddresses = optional(list(object({
          customBgpIpAddresses = list(string)
          ipconfigurationId    = string
        })))
        peerWeight = optional(number, 0)
      }))
      enableBgpRouteTranslationForNat = optional(bool, false)
      isRoutingPreferenceInternet     = optional(bool, false)
      sku                             = optional(string)
      natRules                        = optional(list(any))
      virtualHub = optional(object({
        id = string
      }))
      vpnGatewayScaleUnit = optional(number, 1)
    }))
  }))

  description = "merged vpnGateway artefacts sourced from library"
}

variable "vpn_site_artefacts" {
  type = map(object({
    filePath = string
    artefact = optional(object({
      artefactName = string
      name         = string

      location = optional(string, null)

      addressSpace = optional(object({
        addressPrefixes = list(string)
      }), null)
      deviceProperties = optional(object({
        deviceModel  = optional(string, null)
        deviceVendor = optional(string, null)
      }), null)
      o365Policy = optional(object({
        breakOutCategories = object({
          allow    = optional(bool, null)
          default  = optional(bool, null)
          optimize = optional(bool, null)
        })
      }), null)
      vpnSiteLinks = list(object({
        name = string
        properties = object({
          bgpProperties = optional(object({
            asn               = number
            bgpPeeringAddress = string
          }), null)
          fqdn      = optional(string)
          ipAddress = optional(string)
          linkProperties = optional(object({
            linkProviderName = optional(string, null)
            linkSpeedInMbps  = optional(number, null)
          }), null)
        })
      }))
    }))
  }))
  description = "merged vpnSite artefacts sourced from library"
}

variable "vpn_connection_artefacts" {
  type = map(object({
    filePath = string
    artefact = optional(object({
      artefactName = string
    }))
  }))
  description = "merged vpnConnection artefacts sourced from library"
}

variable "ecp_archetype_definitions" {
  type = object({
    virtual_network        = optional(string, null)
    virtual_network_subnet = optional(list(string), [])
    vpn_gateway            = optional(list(string), [])
    vpn_site               = optional(list(string), [])
    vpn_connection         = optional(list(string), [])
    er_gateway             = optional(list(string), [])
    er_connection          = optional(list(string), [])
  })
  default = {
    virtual_network = "l2-connectivity-vnet-hub"
    virtual_network_subnet = [
      "l2-connectivity-management-subnet-default"
    ]
    vpn_gateway    = []
    vpn_site       = []
    vpn_connection = []
    er_gateway     = []
    er_connection  = []
  }
  description = "The ECP archetype definitions by 'archetypeName' which are valid for this deployment."
}

variable "key_vault_id" {
  type        = string
  default     = null
  description = "The ID of an existing Key Vault to use for storing secrets."
}
