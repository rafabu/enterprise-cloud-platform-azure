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
  nat_gateway_resource_id = var.nat_gateway_creation_enabled && length(local.nat_gateway_observed_resource_id) > 0 ? local.nat_gateway_observed_resource_id : var.nat_gateway_resource_id != null ? var.nat_gateway_resource_id : null
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

  lifecycle {
    ignore_changes = [
      body,
    ]
  }
}
