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
    id                  = module.managed_devops_pool.resource_id
    name                = module.managed_devops_pool.name
    resource_group_name = azurerm_resource_group.mpool.name
    location            = azurerm_resource_group.mpool.location
  }
}
