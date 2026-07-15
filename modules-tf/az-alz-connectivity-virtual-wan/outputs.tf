output "azure_virtual_wan_name" {
  value       = module.alz-connectivity-virtual-wan.name
  description = "The name of the virtual WAN."
}

output "azure_virtual_wan_resource_id" {
  value       = module.alz-connectivity-virtual-wan.resource_id
  description = "The resource ID of the virtual WAN."
}

output "azure_virtual_wan_hub_resource_ids" {
  value       = module.alz-connectivity-virtual-wan.virtual_hub_resource_ids
  description = "The resource IDs of the virtual hubs associated with the virtual WAN."
}

output "azure_virtual_wan_hub_resource_names" {
  value       = module.alz-connectivity-virtual-wan.virtual_hub_resource_names
  description = "The names of the virtual hubs associated with the virtual WAN."
}

output "azure_virtual_wan_hub_resource_details" {
  value = {
    for k, v in data.azapi_resource.virtual_wan_hub_details : k => {
      name     = v.name
      id       = v.id
      location = v.location
      address_prefix             = v.output.properties["addressPrefix"]
      network_virtual_appliances = v.output.properties["networkVirtualAppliances"]
      virtual_router_asn         = v.output.properties["virtualRouterAsn"]
      virtual_router_ips         = v.output.properties["virtualRouterIps"]
    }
  }
  description = "The detailed properties of the virtual hubs associated with the virtual WAN."
}

output "azure_virtual_wan_hub_resource_details_by_location" {
  value = {
    for location in distinct([
      for v in data.azapi_resource.virtual_wan_hub_details : v.location
    ]) : lower(location) => (
      [
        for k, v in data.azapi_resource.virtual_wan_hub_details :
        {
          name     = v.name
          id       = v.id
          location = v.location
          address_prefix             = v.output.properties["addressPrefix"]
          network_virtual_appliances = v.output.properties["networkVirtualAppliances"]
          virtual_router_asn         = v.output.properties["virtualRouterAsn"]
          virtual_router_ips         = v.output.properties["virtualRouterIps"]
        }
        if v.location == location
      ][0]
    )
  }
  description = "The detailed properties of the first virtual hub for each location associated with the virtual WAN. Keyed by location."
}
