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
    alias               = local.ado_agent_pool_alias
    name                = local.ado_agent_pool_alias
    resource_name       = azapi_resource.managed_devops_pool.name
    resource_group_name = azurerm_resource_group.mpool.name
    location            = azurerm_resource_group.mpool.location
  }
}

output "managed_devops_pool_quota" {
  value = {
    id       = local.quota_request_id
    provider = "Microsoft.DevOpsInfrastructure"
    region   = var.azure_location

    name = local.managed_devops_pool_usage.sku_family
    # values as after (hopefully) successful quota request
    limit         = local.managed_devops_pool_usage_finally.limit
    current_usage = local.managed_devops_pool_usage_finally.current_usage
  }
}

output "nat_gateway" {
  value = local.mpool_nat_gateway_deploy ? {
    id                  = azurerm_nat_gateway.mpool["do"].id
    name                = azurerm_nat_gateway.mpool["do"].name
    resource_group_name = azurerm_resource_group.mpool.name
    location            = azurerm_resource_group.mpool.location
    public_ip_address   = azurerm_public_ip.mpool["do"].ip_address
  } : null
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

