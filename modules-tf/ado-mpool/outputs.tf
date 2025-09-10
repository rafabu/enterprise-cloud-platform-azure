output "resource_group" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.mpool.id
}

output "virtual_network_subnets" {
  description = "core properties of virtual networks subnets"
  value = {
    for key, val in azurerm_subnet.mpool : key => {
      id                   = val.id,
      name                 = val.name,
      virtual_network_name = val.virtual_network_name
      resource_group_name  = val.resource_group_name
      address_prefixes     = val.address_prefixes
    }
  }
}

output "workload_identities" {
  description = "core properties of managed identities / service principals"
  value = { for key, val in merge(
    data.azuread_service_principal.mpool,
    azuread_service_principal.mpool
    ) : key => {
    id                     = val["id"]
    client_id              = val["client_id"]
    display_name           = val["display_name"]
    object_id              = val["object_id"]
    workload_identity_type = val.workload_identity_type
    }
  }
}

