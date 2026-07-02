output "subscription_resource_id" {
  value       = module.alz_management.resource_id
  description = "The Azure resource id of the subscription that resources have been deployed into."
}
