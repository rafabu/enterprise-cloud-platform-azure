module "alz-connectivity-virtual-wan" {
  source  = "Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm"
  version = "0.13.5"

  providers = {
    azurerm = azurerm.connectivity
  }

  ### Naming resources
  default_naming_convention = {
    virtual_wan_name = "${data.azurecaf_name.vwan.result}-$${location}-$${sequence}"
    virtual_hub_name = "${replace(data.azurecaf_name.vwan.result, "-vwan-", "-vhub-")}-$${location}-$${sequence}"
    # sidecar_virtual_network_name               = "vnet-sidecar-$${location}-$${sequence}"
    # firewall_name                              = "fw-hub-$${location}-$${sequence}"
    # firewall_policy_name                       = "fwp-hub-$${location}-$${sequence}"
    # virtual_network_gateway_express_route_name = "vgw-hub-er-$${location}-$${sequence}"
    # virtual_network_gateway_vpn_name           = "vgw-hub-vpn-$${location}-$${sequence}"
    # private_dns_resolver_name                  = "pdr-hub-$${location}-$${sequence}"
    # bastion_host_name                          = "bas-hub-$${location}-$${sequence}"
    # bastion_host_public_ip_name                = "pip-bas-hub-$${location}-$${sequence}"
    # ddos_protection_plan_name                  = "ddos-hub-$${location}-$${sequence}"
  }
  default_naming_convention_sequence = {
    padding_format  = "%02d"
    starting_number = 1
  }

  virtual_wan_settings = {
    enabled_resources = {
      ddos_protection_plan = false
    }
    virtual_wan = {
      # name                              = optional(string)
      location                          = lower(var.azure_location)
      resource_group_name               = "${data.azurecaf_name.rg.result}-vwan-${lower(var.azure_location)}"
      type                              = "Basic" # "Standard"
      allow_branch_to_branch_traffic    = true
      disable_vpn_encryption            = false
      office365_local_breakout_category = "None"
      tags                              = var.azure_tags
    }
    ddos_protection_plan = {}
  }

  virtual_hubs = {
    for vhub_key, vhub_value in local.virtual_wan_hubs : vhub_key => {

      enabled_resources = {
        firewall                              = false
        firewall_policy                       = false
        bastion                               = false
        virtual_network_gateway_express_route = false
        virtual_network_gateway_vpn           = false
        private_dns_zones                     = false
        private_dns_resolver                  = false
        sidecar_virtual_network               = false
      }

      location = vhub_value.location

      hub = {
        address_prefix                         = vhub_value.address_prefix
        parent_id                              = vhub_value.resource_group_id
        sku                                    = vhub_value.sku
        hub_routing_preference                 = vhub_value.hub_routing_preference
        virtual_router_auto_scale_min_capacity = vhub_value.virtual_router_auto_scale_min_capacity
        tags                                   = vhub_value.tags
      }

      virtual_network_connections = length(vhub_value.virtual_network_connections) > 0 ? vhub_value.virtual_network_connections : null

      # express_route_circuit_connections = []

      # p2s_gateway_vpn_server_configurations = []

      # p2s_gateways = []

      # routing_intents = {}

      # vpn_site_connections = {}

      # vpn_sites = {}

      # sidecar_virtual_network = {}

      # firewall = {}

      # firewall_policy = {}

      # bastion = {}

      # virtual_network_gateways = {}

      # private_dns_zones = {}

      # private_dns_resolver = {}
    }

  }

  tags = {}

  enable_telemetry = false

  depends_on = [
    azapi_resource.resource_group_vwan,
    azapi_resource.resource_group_vwan_hub
  ]
}
