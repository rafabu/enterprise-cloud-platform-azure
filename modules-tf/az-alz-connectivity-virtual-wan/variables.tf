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

    # location                     = optional(string, null)
    # address_prefix_artefact_name = string

    #sku                                    = optional(string, null)
    # hub_routing_preference                 = optional(string, "ExpressRoute")
    # virtual_router_auto_scale_min_capacity = optional(number, 2)
    # tags                                   = optional(map(string))

    ### Virtual Network Connections ###
    virtual_network_connections = optional(map(object({
      # name                      = string
      remote_virtual_network_id = string
      internet_security_enabled = optional(bool)
      routing = optional(object({
        associated_route_table_id  = optional(string)
        associated_route_table_key = optional(string)
        propagated_route_table = optional(object({
          route_table_ids  = optional(list(string))
          route_table_keys = optional(list(string))
          labels           = optional(list(string))
        }))
        inbound_route_map_id  = optional(string)
        outbound_route_map_id = optional(string)
      }))
    })), {})

    ### Virtual Network Gateways ###
    virtual_network_gateways = optional(object({
      subnet_address_prefix                     = optional(string)
      subnet_default_outbound_access_enabled    = optional(bool, false)
      route_table_creation_enabled              = optional(bool, false)
      route_table_name                          = optional(string)
      route_table_bgp_route_propagation_enabled = optional(bool, false)

      express_route = optional(object({
        name                          = optional(string)
        allow_non_virtual_wan_traffic = optional(bool, false)
        scale_units                   = optional(number, 1)
        tags                          = optional(map(string))
      }), {})

      vpn = optional(object({
        name                                  = optional(string)
        bgp_route_translation_for_nat_enabled = optional(bool)
        bgp_settings = optional(object({
          instance_0_bgp_peering_address = optional(object({
            custom_ips = list(string)
          }))
          instance_1_bgp_peering_address = optional(object({
            custom_ips = list(string)
          }))
          peer_weight = number
          asn         = number
        }))
        routing_preference = optional(string)
        scale_unit         = optional(number)
        tags               = optional(map(string))
      }), {})
    }), {})

    ### VPN Sites ###
    vpn_sites = optional(map(object({
      name = optional(string)
      links = list(object({
        name = string
        bgp = optional(object({
          asn             = number
          peering_address = string
        }))
        fqdn          = optional(string)
        ip_address    = optional(string)
        provider_name = optional(string)
        speed_in_mbps = optional(number)
        }
      ))
      address_cidrs = optional(list(string))
      device_model  = optional(string)
      device_vendor = optional(string)
      o365_policy = optional(object({
        traffic_category = object({
          allow_endpoint_enabled    = optional(bool)
          default_endpoint_enabled  = optional(bool)
          optimize_endpoint_enabled = optional(bool)
        })
      }))
      tags = optional(map(string))
    })), {})


    ### VPN Site Connections ###
    vpn_site_connections = optional(map(object({
      name         = optional(string)
      vpn_site_key = string
      vpn_links = list(object({
        egress_nat_rule_ids  = optional(list(string))
        ingress_nat_rule_ids = optional(list(string))
        vpn_site_link_number = number
        bandwidth_mbps       = optional(number)
        bgp_enabled          = optional(bool)
        connection_mode      = optional(string, "Default")

        ipsec_policy = optional(object({
          dh_group                 = string
          ike_encryption_algorithm = string
          ike_integrity_algorithm  = string
          encryption_algorithm     = string
          integrity_algorithm      = string
          pfs_group                = string
          sa_data_size_kb          = string
          sa_lifetime_sec          = string
        }))
        protocol                              = optional(string, "IKEv2")
        ratelimit_enabled                     = optional(bool, false)
        route_weight                          = optional(number)
        shared_key                            = optional(string)
        local_azure_ip_address_enabled        = optional(bool)
        policy_based_traffic_selector_enabled = optional(bool)
        custom_bgp_addresses = optional(list(object({
          ip_address = string
          instance   = number
        })))
      }))
      internet_security_enabled = optional(bool)
      routing = optional(object({
        associated_route_table = string
        propagated_route_table = optional(object({
          route_table_ids = optional(list(string))
          labels          = optional(list(string))
        }))
        inbound_route_map_id  = optional(string)
        outbound_route_map_id = optional(string)
      }))
      traffic_selector_policy = optional(object({
        local_address_ranges  = list(string)
        remote_address_ranges = list(string)
      }))
    })), {})


  }))
  description = "A map of Virtual WAN hubs to create."
  default     = {}

  validation {
    condition     = alltrue([for hub in var.virtual_wan_hubs : !try(hub.enabled_resources.virtual_network_gateway_express_route, false)])
    error_message = "vWAN has Type 'Basic' which does not support ExpressRouteGateway. To use enabled_resources.virtual_network_gateway_express_route set the virtual_wan.type to 'Standard'."
  }
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
}

variable "virtual_hub_artefacts" {
  type = map(object({
    filePath = string
    artefact = optional(object({
      artefactName = string
      nameElement  = optional(string)

      location = optional(string)

      addressPrefix        = optional(string)
      hubRoutingPreference = optional(string)
      sku                  = optional(string)
      virtualRouterAutoScaleConfiguration = optional(object({
        minCapacity = number
      }))
      virtualWan = optional(object({
        id = string
      }))
    }))
  }))
  description = "merged virtualHub artefacts sourced from library"
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

      addressSpace = object({
        addressPrefixes = list(string)
      })
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

output "zzz_vpn_site_artefacts" {
  value       = var.vpn_site_artefacts
  description = "Debug output of the parsed_vpn_site_artefacts local."
}

# output "zzz_vpn_gateway_locations" {
#   value       = local.vpn_gateway_location_info
#   description = "Debug output of the vpn_gateway_locations local."
# }

# output "zzz_vpn_gateway_objects_hub_resolved" {
#   value       = local.vpn_gateway_objects_hub_resolved
#   description = "Debug output of the vpn_gateway_objects_hub_resolved local."
# }
