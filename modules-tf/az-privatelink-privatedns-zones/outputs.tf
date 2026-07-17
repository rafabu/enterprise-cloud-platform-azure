# output used to link vnets with the private DNS zones by downstream modules
output "private_link_resource_group_id" {
  value       = azapi_resource.resource_group.id
  description = "The resource group ID of the private DNS zones."
}

output "private_link_private_dns_zones_resource_ids" {
  value = distinct([
    for key, val in module.private_dns_zones.private_dns_zone_resource_ids : val
  ])
}

output "private_link_private_dns_zones" {
  value = module.private_dns_zones.private_dns_zone_resource_ids
}
