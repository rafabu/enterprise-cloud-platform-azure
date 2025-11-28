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
    id_azuredevops      = data.azuredevops_agent_pool.mpool.id
    name                = azapi_resource.managed_devops_pool.name
    resource_group_name = azurerm_resource_group.mpool.name
    location            = azurerm_resource_group.mpool.location
  }
}

output "managed_devops_pool_quota" {
  value = {
    id       = local.quota_request_set_url
    provider = "Microsoft.DevOpsInfrastructure"
    region   = var.azure_location

    name          = local.managed_devops_pool_sku_family
    # values as forseen after successful quota request
    limit         = local.managed_devops_pool_usage.limit + local.managed_devops_pool_usage.this_missing_cpu_count
    current_usage = local.managed_devops_pool_usage.current_usage + local.managed_devops_pool_usage.this_sku_cpu_count_total
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

