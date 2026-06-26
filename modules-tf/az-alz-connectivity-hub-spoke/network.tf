module "network" {
  source  = "Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm"
  version = var.avm-ptn-alz-connectivity-hub-and-spoke-vnet_version

  providers = {
    azurerm = azurerm.connectivity
  }

  ### Naming resources
  default_naming_convention = {
    virtual_network_name = "${data.azurecaf_name.vnet.result}-$${location}"
    firewall_name        = "${replace(data.azurecaf_name.vnet.result, "-vnet-", "-afw-")}-$${location}"
    firewall_policy_name = "${replace(data.azurecaf_name.vnet.result, "-vnet-", "-afwp-")}-$${location}"

    firewall_public_ip_name            = "${replace(data.azurecaf_name.vnet.result, "-vnet-", "-afw-")}-$${location}-pip-$${sequence}"
    firewall_management_public_ip_name = "${replace(data.azurecaf_name.vnet.result, "-vnet-", "-afw-")}-$${location}-pip-mgmt-$${sequence}"
    # route_table_firewall_name
    # route_table_user_subnets_name

    virtual_network_gateway_express_route_name = "${replace(data.azurecaf_name.vnet.result, "-vnet-", "-erc-")}-$${location}"
    # virtual_network_gateway_express_route_ip_configuration_name = "${replace(data.azurecaf_name.vnet.result, "-vnet-", "-erc-")}-$${location}-pip-$${sequence}"
    virtual_network_gateway_express_route_public_ip_name = "${replace(data.azurecaf_name.vnet.result, "-vnet-", "-erc-")}-$${location}-pip-$${sequence}"


    virtual_network_gateway_vpn_name = "${replace(data.azurecaf_name.vnet.result, "-vnet-", "-vpng-")}-$${location}"
    # virtual_network_gateway_vpn_ip_configuration_name = "${local.default_naming_convention.virtual_network_gateway_vpn_name}-pip-$${sequence}"
    virtual_network_gateway_vpn_public_ip_name = "${replace(data.azurecaf_name.vnet.result, "-vnet-", "-vpng-")}-$${location}-pip-$${sequence}"
    virtual_network_gateway_route_table_name   = "${replace(data.azurecaf_name.vnet.result, "-vnet-", "-vpng-")}-$${location}-rt-$${sequence}"


    private_dns_resolver_name   = "${replace(data.azurecaf_name.vnet.result, "-vnet-", "-dnspr-")}-$${location}-$${sequence}"
    bastion_host_name           = "${replace(data.azurecaf_name.vnet.result, "-vnet-", "-bas-")}-$${location}-$${sequence}"
    bastion_host_public_ip_name = "${replace(data.azurecaf_name.vnet.result, "-vnet-", "-pip-")}-$${location}-$${sequence}"
    ddos_protection_plan_name   = "${data.azurecaf_name.ddospp.result}-$${location}-$${sequence}"
    nat_gateway_name            = "${replace(data.azurecaf_name.vnet.result, "-vnet-", "-nat-")}-$${location}-$${sequence}"


  }
  default_naming_convention_sequence = {
    padding_format  = "%02d"
    starting_number = 1
  }

  hub_and_spoke_networks_settings = {
    enabled_resources = {
      ddos_protection_plan = false
    }
    ddos_protection_plan = {}
  }

  hub_virtual_networks = {
    main = {
      enabled_resources = {
        firewall                              = false
        firewall_policy                       = false
        virtual_network_gateway_express_route = false
        virtual_network_gateway_vpn           = false
        private_dns_zones                     = false
        private_dns_resolver                  = false
        dns_resolver_policy                   = false
        bastion                               = false
        nat_gateway                           = true
      }

      location          = lower(var.azure_location)
      default_parent_id = azapi_resource.resource_group_vnet.id

      # default_hub_address_space = var.ecp_network_main_ipv4_address_space

      hub_virtual_network = {
        ##### address_space = local.virtual_network_address_prefixes_location_object
        address_space = [
          "10.254.2.0/23",
          "10.254.4.0/22",
          "10.254.16.0/20"
        ]

        subnets = {
          gatewaysubnet = {
            name = "GatewaySubnet"
            address_prefixes = [
              "10.254.2.0/26"
            ]

            nat_gateway = {
              assign_generated_nat_gateway = false
            }

            private_endpoint_network_policies_enabled     = false
            private_link_service_network_policies_enabled = false

            default_outbound_access_enabled = false
          }
          azurefirewallsubnet = {
            name = "AzureFirewallSubnet"
            address_prefixes = [
              "10.254.2.64/26"
            ]

            nat_gateway = {
              assign_generated_nat_gateway = false
            }

            private_endpoint_network_policies_enabled     = false
            private_link_service_network_policies_enabled = false

            default_outbound_access_enabled = false
          }
        }
      }
      nat_gateway = {
        public_ip_configurations = [
          {
            name = "nat-gateway-pip"
          }
        ]
      }
    }
  }

  timeouts = {
    # initial creation of vWAN components can take well over an hour
    create = "90m"
  }

  tags = var.azure_tags

  enable_telemetry = false
}
