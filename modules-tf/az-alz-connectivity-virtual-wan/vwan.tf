module "alz-connectivity-virtual-wan" {
  source  = "Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm"
  version = "0.13.5"

  providers = {
    azurerm = azurerm.connectivity
  }

  ### Naming resources
  default_naming_convention = {
    virtual_wan_name                           = "${data.azurecaf_name.vwan.result}-$${location}-$${sequence}"
    virtual_hub_name                           = "${replace(data.azurecaf_name.vwan.result, "-vwan-", "-vhub-")}-$${location}-$${sequence}"
    sidecar_virtual_network_name               = "${data.azurecaf_name.vnet.result}-$${location}-$${sequence}"
    firewall_name                              = "${replace(data.azurecaf_name.vwan.result, "-vwan-", "-afw-")}-$${location}-$${sequence}"
    firewall_policy_name                       = "${replace(data.azurecaf_name.vwan.result, "-vwan-", "-afwp-")}-$${location}-$${sequence}"
    virtual_network_gateway_express_route_name = "${replace(data.azurecaf_name.vwan.result, "-vwan-", "-erc-")}-$${location}-$${sequence}"
    virtual_network_gateway_vpn_name           = "${replace(data.azurecaf_name.vwan.result, "-vwan-", "-vpng-")}-$${location}-$${sequence}"
    private_dns_resolver_name                  = "${replace(data.azurecaf_name.vwan.result, "-vwan-", "-dnspr-")}-$${location}-$${sequence}"
    bastion_host_name                          = "${replace(data.azurecaf_name.vwan.result, "-vwan-", "-bas-")}-$${location}-$${sequence}"
    bastion_host_public_ip_name                = "${replace(data.azurecaf_name.vwan.result, "-vwan-", "-pip-")}-$${location}-$${sequence}"
    ddos_protection_plan_name                  = "${data.azurecaf_name.ddospp.result}-$${location}-$${sequence}"
  }
  default_naming_convention_sequence = {
    padding_format  = "%02d"
    starting_number = 1
  }

  virtual_wan_settings = {
    enabled_resources = {
      ddos_protection_plan = false
    }
    ddos_protection_plan = {}

    # consider the 1st virtual_wan object
    virtual_wan = local.virtual_wan_object
  }

  # if no hubs are defined, the AVM module will not deploy any vWAN resources (not even the vWAN itself)
  #     so if no WAN artefact is defined, deactivate the hubs as well, otherwise a default WAN would be created.
  virtual_hubs = length(values(local.virtual_hub_map)[0]) > 0 ? {
    for vhub_key, vhub_value in local.virtual_hub_map : vhub_key => {

      enabled_resources = vhub_value.enabled_resources

      location = vhub_value.location

      hub = {
        # add vwan/hub location index to name if non-default hub key
        name                                   = vhub_key == "ecpa_${lower(vhub_value.location)}_${vhub_value.address_prefix}" ? "${replace(data.azurecaf_name.vwan.result, "-vwan-", "-vhub-")}-${lower(local.location_code[vhub_value.location])}-01" : "${replace(data.azurecaf_name.vwan.result, "-vwan-", "-vhub-")}-${lower(local.location_code[vhub_value.location])}-${format("%02d", random_integer.virtual_hub_id[vhub_key].result)}"
        address_prefix                         = vhub_value.address_prefix
        parent_id                              = vhub_value.resource_group_id
        sku                                    = vhub_value.sku
        hub_routing_preference                 = vhub_value.hub_routing_preference
        virtual_router_auto_scale_min_capacity = vhub_value.virtual_router_auto_scale_min_capacity
      }

      virtual_network_connections = try(vhub_value.virtual_network_connections, {})

      # express_route_circuit_connections = []

      # p2s_gateway_vpn_server_configurations = []

      # p2s_gateways = []

      # routing_intents = {}

      vpn_site_connections = try(vhub_value.vpn_site_connections, {})

      vpn_sites = try(vhub_value.vpn_sites, {})

      # sidecar_virtual_network = {}

      # firewall = {}

      # firewall_policy = {}

      # bastion = {}

      # vnet gateways are deployed based on enabled_resources.virtual_network_gateway_vpn / enabled_resources.virtual_network_gateway_express_route
      #     this object allows configuring properties that are non-default
      #     hence: null --> default settings
      virtual_network_gateways = try(vhub_value.virtual_network_gateways, {})

      # private_dns_zones = {}

      # private_dns_resolver = {}
    }

  } : {}

  timeouts = {
    # initial creation of vWAN components can take well over an hour
    create = "90m"
  }

  tags = var.azure_tags

  enable_telemetry = false

  depends_on = [
    azapi_resource.resource_group_vwan,
    azapi_resource.resource_group_vwan_hub
  ]
}

# provider additional output for downstream units (e.g. router IPs)
data "azapi_resource" "virtual_wan_hub_details" {
  for_each = local.virtual_hub_map

  type        = "Microsoft.Network/virtualHubs@2025-05-01"
  resource_id = module.alz-connectivity-virtual-wan.virtual_hub_resource_ids[each.key]

  response_export_values = [
    "properties.addressPrefix",
    "properties.virtualRouterAsn",
    "properties.virtualRouterIps",
    "properties.virtualHubRouteTableV2s",
    "properties.routeTable",
    "properties.virtualRouterAutoScaleConfiguration",
    "properties.networkVirtualAppliances",
    "properties.vpnGateway.id"
  ]

  depends_on = [
    azapi_resource.resource_group_vwan,
    azapi_resource.resource_group_vwan_hub
  ]
}
