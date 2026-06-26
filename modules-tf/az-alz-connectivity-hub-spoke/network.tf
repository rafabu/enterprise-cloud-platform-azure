# module "alz-connectivity-virtual-wan" {
#   source  = "Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm"
#   version = var.avm-ptn-alz-connectivity-hub-and-spoke-vnet_version

#   providers = {
#     azurerm = azurerm.connectivity
#   }

#   ### Naming resources
#   default_naming_convention = {
#     virtual_network_name = "${data.azurecaf_name.vnet.result}-$${location}-$${sequence}"
#     firewall_name        = "${replace(data.azurecaf_name.vnet.result, "-vnet-", "-afw-")}-$${location}-$${sequence}"
#     firewall_policy_name = "${replace(data.azurecaf_name.vnet.result, "-vnet-", "-afwp-")}-$${location}-$${sequence}"

# firewall_public_ip_name = "${local.default_naming_convention.firewall_name}-pip-$${sequence}"
# firewall_management_public_ip_name = "${local.default_naming_convention.firewall_name}-pip-mgmt-$${sequence}"
# # route_table_firewall_name
# # route_table_user_subnets_name

#  virtual_network_gateway_express_route_name = "${replace(data.azurecaf_name.vnet.result, "-vnet-", "-erc-")}-$${location}-$${sequence}"
#  # virtual_network_gateway_express_route_ip_configuration_name = "${local.default_naming_convention.virtual_network_gateway_express_route_name}-pip-$${sequence}"
#  virtual_network_gateway_express_route_public_ip_name = "${local.default_naming_convention.virtual_network_gateway_express_route_name}-pip-$${sequence}"


#   virtual_network_gateway_vpn_name           = "${replace(data.azurecaf_name.vnet.result, "-vnet-", "-vpng-")}-$${location}-$${sequence}"
# # virtual_network_gateway_vpn_ip_configuration_name = "${local.default_naming_convention.virtual_network_gateway_vpn_name}-pip-$${sequence}"
# virtual_network_gateway_vpn_public_ip_name = "${local.default_naming_convention.virtual_network_gateway_vpn_name}-pip-$${sequence}"
# virtual_network_gateway_route_table_name = "${local.default_naming_convention.virtual_network_gateway_vpn_name}-rt-$${sequence}"


#     private_dns_resolver_name                  = "${replace(data.azurecaf_name.vnet.result, "-vnet-", "-dnspr-")}-$${location}-$${sequence}"
#     bastion_host_name                          = "${replace(data.azurecaf_name.vnet.result, "-vnet-", "-bas-")}-$${location}-$${sequence}"
#     bastion_host_public_ip_name                = "${replace(data.azurecaf_name.vnet.result, "-vnet-", "-pip-")}-$${location}-$${sequence}"
#     ddos_protection_plan_name                  = "${data.azurecaf_name.ddospp.result}-$${location}-$${sequence}"
#     nat_gateway_name                            = "${replace(data.azurecaf_name.vnet.result, "-vnet-", "-nat-")}-$${location}-$${sequence}"


#   }
#   default_naming_convention_sequence = {
#     padding_format  = "%02d"
#     starting_number = 1
#   }

# hub_and_spoke_networks_settings = {
#     enabled_resources = {
#       ddos_protection_plan = false
#     }
#     ddos_protection_plan = {}

#     # consider the 1st virtual_network object
#     virtual_network = local.virtual_network_object
#   }





#   timeouts = {
#     # initial creation of vWAN components can take well over an hour
#     create = "90m"
#   }

#   tags = var.azure_tags

#   enable_telemetry = false

#   depends_on = [
#     azapi_resource.resource_group_vnet
#   ]
# }
