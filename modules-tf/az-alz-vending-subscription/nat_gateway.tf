# keeper value written to tag hidden-natGateways-keeper on the NAT Gateway created
resource "random_uuid" "nat_gateway_keeper" {
  for_each = toset(var.nat_gateway_creation_enabled ? ["this"] : [])

  keepers = {
    subscription_id            = var.subscription_id
    subscription_alias_name    = null
    subscription_billing_scope = null
  }
}

# discover NAT Gateways across all subscriptions under the target management group
data "azapi_resource_action" "nat_gateway_discovery" {
  for_each = toset(var.nat_gateway_creation_enabled ? ["this"] : [])

  type        = "Microsoft.ResourceGraph@2024-04-01"
  resource_id = "/providers/Microsoft.ResourceGraph"
  action      = "resources"

  body = {
    managementGroups = [var.subscription_management_group_id]
    query            = <<-KQL
      resources
      | where type =~ "Microsoft.Network/natGateways"
      | where tostring(tags["hidden-natGateways-keeper"]) == "${random_uuid.nat_gateway_keeper[each.key].result}"
      | project id, name, subscriptionId, resourceGroup, location, tags
    KQL
    options = {
      resultFormat = "objectArray"
    }
  }

  response_export_values = ["count", "data"]
}

locals {
  nat_gateway_observed_resource_id = try(data.azapi_resource_action.nat_gateway_discovery["this"].output.data[0].id, "")
  # NAT Gateway resource ID to be fed into subnet object of vending AVM module
  #     must be known before apply so build it manually using the resource group and NAT Gateway name
  nat_gateway_resource_id = var.nat_gateway_creation_enabled ? provider::azapi::resource_group_resource_id(
    module.vending.subscription_id,
    local.resource_groups.vnet.name,
    "Microsoft.Network/natGateways",
    [replace(data.azurecaf_name.rg.result, "-rg-", "-ng-")]
  ) : length(local.nat_gateway_observed_resource_id) > 0 ? local.nat_gateway_observed_resource_id : null
}

module "nat_gateway" {
  source  = "Azure/avm-res-network-natgateway/azurerm"
  version = var.avm-res-network-natgateway_version

  for_each = toset(var.nat_gateway_creation_enabled ? ["this"] : [])

  name      = replace(data.azurecaf_name.rg.result, "-rg-", "-ng-")
  location  = var.azure_location
  parent_id = module.vending.resource_group_resource_ids["vnet"]

  public_ip_configuration = {
    for i in range(var.nat_gateway_public_ip_count) : i => {
      inherit_tags = true
      ip_version   = "IPv4"
      sku          = "StandardV2"
      sku_tier     = "Regional"
      zones        = null
    }
  }

  public_ips = {
    for i in range(var.nat_gateway_public_ip_count) : i => {
      name = "${data.azurecaf_name.pip.result}-${format("%02d", i + 1)}"
    }
  }

  sku_name = "StandardV2"
  zones    = null

  tags = merge(
    var.azure_tags,
    # add distinct keeper tag to NAT Gateway resource created (allows discovering if it has already been deployed or not)
    {
      "hidden-natGateways-keeper" = random_uuid.nat_gateway_keeper[each.key].result
    }
  )

  enable_telemetry = false

  depends_on = []
}

resource "time_sleep" "nat_gateway_pre_destroy_delay" {
  # destroy only: after destroying *_subnet_nat_gateway_link resources
  #     we have to wait for Entra Id replication or subnet_nat_gateway_link
  #     destroy operation will fail.

  destroy_duration = "15s" # wait until ALL subnets are destroyed

  depends_on = [module.nat_gateway]
}

# after initial creation of NAT Gateway, update it directly on the subnets
resource "azapi_update_resource" "subnet_nat_gateway_link" {
  for_each = var.nat_gateway_creation_enabled ? local.virtual_networks : {}

  type        = "Microsoft.Network/virtualNetworks@2025-05-01"
  resource_id = module.vending.virtual_network_resource_ids[each.key]

  body = {
    properties = {
      subnets = [
        for key, val in each.value.subnets : {
          id   = "${module.vending.virtual_network_resource_ids[each.key]}/subnets/${val.name}"
          name = val.name
          properties = {
            natGateway = {
              id = module.nat_gateway["this"].resource_id
            }
          }
        }
        if val.private_endpoint_allocate == false
      ]
    }
  }

  retry = {
    error_message_regex  = ["AnotherOperationInProgress"]
    interval             = 5
    max_interval_seconds = 30
  }

  depends_on = []

  lifecycle {
    ignore_changes = [
      body
    ]
  }
}

#########  DESTROY Logic here #########
# in order to disassociate the NAT Gateway from subnets,
#    a full "PUT" operation is required on each subnet. This
#    must include ALL other properties. Hence, datasource, then
#    feeding it into a DESTROY-ONLY azapi_resource_action.
#    If this isn't done, deleting NAT gateway will most oftenfail due
#    to timing issues.
data "azapi_resource" "subnet" {
  for_each = var.nat_gateway_creation_enabled ? local.subnet_resource_ids_by_vnet_object : {}

  resource_id = each.value.subnet_id
  type        = "Microsoft.Network/virtualNetworks/subnets@2026-05-01"

  response_export_values = ["*"]
}

locals {
  subnet_resource_ids_by_vnet_list = [
    for vnet_key, vnet_val in local.virtual_networks : {
      for subnet_key, subnet_val in vnet_val.subnets : "${vnet_key}_${subnet_key}" => {
        resource_group_key        = vnet_val.resource_group_key
        vnet_key                  = vnet_key
        subnet_key                = subnet_key
        subnet_id                 = "${module.vending.virtual_network_resource_ids[vnet_key]}/subnets/${subnet_val.name}"
        private_endpoint_allocate = subnet_val.private_endpoint_allocate
      }
    }
  ]
  subnet_resource_ids_by_vnet_object = zipmap(
    flatten([for entry, attr in local.subnet_resource_ids_by_vnet_list : keys(attr)]),
    flatten([for entry, attr in local.subnet_resource_ids_by_vnet_list : values(attr)])
  )
}

resource "azapi_resource_action" "subnet_nat_gateway_unlink_on_destroy" {
  # unassign the NAT Gateway from subnets on destroy (PATCH), never delete the subnets themselves
  for_each = var.nat_gateway_creation_enabled ? local.subnet_resource_ids_by_vnet_object : {}

  type        = "Microsoft.Network/virtualNetworks/subnets@2026-05-01"
  resource_id = each.value.subnet_id
  method      = "PUT"

  body = {
    # location = "WestEurope"
    properties = {
      natGateway = null,
      # # need to have NSG here, otherwise policy will complain
      addressPrefixes                   = data.azapi_resource.subnet[each.key].output.properties.addressPrefixes
      defaultOutboundAccess             = data.azapi_resource.subnet[each.key].output.properties.defaultOutboundAccess
      delegations                       = data.azapi_resource.subnet[each.key].output.properties.delegations
      networkSecurityGroup              = data.azapi_resource.subnet[each.key].output.properties.networkSecurityGroup
      privateEndpointNetworkPolicies    = data.azapi_resource.subnet[each.key].output.properties.privateEndpointNetworkPolicies
      privateLinkServiceNetworkPolicies = data.azapi_resource.subnet[each.key].output.properties.privateLinkServiceNetworkPolicies
      serviceEndpoints                  = data.azapi_resource.subnet[each.key].output.properties.serviceEndpoints
    }
  }

  when = "destroy"

  retry = {
    error_message_regex  = ["AnotherOperationInProgress"]
    interval             = 5
    max_interval_seconds = 30
  }

  depends_on = [time_sleep.nat_gateway_pre_destroy_delay]
}
