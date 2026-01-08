output "azure_virtual_wan_name" {
  value       = module.alz-connectivity-virtual-wan.name
  description = "The name of the virtual WAN."
}

output "azure_virtual_wan_resource_id" {
  value       = module.alz-connectivity-virtual-wan.resource_id
  description = "The resource ID of the virtual WAN."
}

output "azure_virtual_wan_hub_resource_ids" {
  value       = module.alz-connectivity-virtual-wan.virtual_hub_ids
  description = "The resource IDs of the virtual hubs associated with the virtual WAN."
}

output "azure_virtual_wan_hub_resource_names" {
  value       = module.alz-connectivity-virtual-wan.virtual_hub_resource_names
  description = "The names of the virtual hubs associated with the virtual WAN."
}