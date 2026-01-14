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
    enabled_resources = optional(object({
      firewall                              = optional(bool, false)
      firewall_policy                       = optional(bool, false)
      bastion                               = optional(bool, false)
      virtual_network_gateway_express_route = optional(bool, false)
      virtual_network_gateway_vpn           = optional(bool, false)
      private_dns_zones                     = optional(bool, false)
      private_dns_resolver                  = optional(bool, false)
      sidecar_virtual_network               = optional(bool, false)
    }), {})

    location                     = optional(string, null)
    address_prefix_artefact_name = string

    sku                                    = optional(string, null)
    hub_routing_preference                 = optional(string, "ExpressRoute")
    virtual_router_auto_scale_min_capacity = optional(number, 2)
    tags                                   = optional(map(string))

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
