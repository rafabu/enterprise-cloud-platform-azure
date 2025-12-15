# output used to link vnets with the private DNS zones by downstream modules
output "private_link_private_dns_zones" {
  value = distinct([
    for key, val in module.private_dns_zones.private_dns_zone_resource_ids : val
  ])
}

output "private_link_private_dns_zones" {
    value = module.private_dns_zones.private_dns_zone_resource_ids
}
