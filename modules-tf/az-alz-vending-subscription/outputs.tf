output "subscription_resource_id" {
  value       = module.vending.resource_id
  description = "The Azure resource id of the subscription that resources have been deployed into."
}

output "vnet_resource_ids" {
  value       = module.vending.virtual_network_resource_ids
  description = "The Azure resource ids of the virtual networks that resources have been deployed into."
}