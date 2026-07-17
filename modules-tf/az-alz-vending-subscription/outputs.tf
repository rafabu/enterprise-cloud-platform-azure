output "subscription_resource_id" {
  value       = module.vending.resource_id
  description = "The Azure resource id of the subscription that resources have been deployed into."
}

output "vnet_resource_ids" {
  value       = module.vending.virtual_network_resource_ids
  description = "The Azure resource ids of the virtual networks that resources have been deployed into."
}

output "storage_account_name" {
  value       = try(module.storage_account["this"].name, "")
  description = "The name of the storage account that may be uses as terraform backend for the subscription."
}

output "storage_account_resource_id" {
  value       = try(module.storage_account["this"].resource_id, "")
  description = "The Azure resource id of the storage account that may be used as terraform backend for the subscription."
}

output "nat_gateway_name" {
  value       = try(provider::azapi::parse_resource_id("Microsoft.Network/natGateways", local.nat_gateway_resource_id).name, null)
  description = "The name of the NAT gateway."
}

output "nat_gateway_resource_id" {
  value       = local.nat_gateway_resource_id
  description = "The Azure resource id of the NAT gateway."
}
