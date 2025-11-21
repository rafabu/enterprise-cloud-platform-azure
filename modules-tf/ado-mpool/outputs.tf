output "resource_group" {
  description = "The ID of the resource group"
  value = {
    id       = azurerm_resource_group.mpool.id
    name     = azurerm_resource_group.mpool.name
    location = azurerm_resource_group.mpool.location
  }
}

output "managed_devops_pool" {
  value = {
    id                  = azapi_resource.managed_devops_pool.id
    name                = azapi_resource.managed_devops_pool.name
    resource_group_name = azurerm_resource_group.mpool.name
    location            = azurerm_resource_group.mpool.location
  }
}

output "service_principals" {
  value = { for key, val in local.workload_identity_objects : key => {
    id           = val.id
    display_name = val.display_name
    client_id    = val.client_id
    object_id    = val.object_id
    type         = val.type
    }
  }
}

