module "devops_project" {
  source = "./modules/devops_project"

  for_each = toset(var.azure_devops_project_name != null ? ["this"] : [])

  azure_devops_project_name        = var.azure_devops_project_name
  azure_devops_project_description = var.azure_devops_project_description

  resource_group_id       = module.vending.resource_group_resource_ids["mgmt"]
  resource_group_location = var.azure_location
  resource_group_tags     = var.azure_tags

  managed_identity_resource_id = azapi_resource.uami.id
  managed_identity_client_id   = azapi_resource.uami.output.properties.clientId
  managed_identity_object_id   = azapi_resource.uami.output.properties.principalId

  service_connection_name = replace(data.azurecaf_name.rg.result, "-rg-", "-srv-conn-")
  variable_group_name     = local.devops_variable_group_name

  # Entra Groups
  owner_permission_group_object_id = module.entra_id_permissions["lz-owner"].permission_group_object_id
  user_permission_group_object_id  = module.entra_id_permissions["lz-user"].permission_group_object_id

  shared_agent_pool_name = var.ecp_azure_devops_managed_devops_pool_name

  storage_account_name        = try(module.storage_account["this"].name, "")
  storage_account_resource_id = try(module.storage_account["this"].resource_id, "")

  vending_managed_identity_client_id = var.ecp_azure_deployment_service_principal_client_id

  depends_on = [
    time_sleep.uami_wait
  ]
}

output "azure_devops_project" {
  value       = module.devops_project
  description = "The Azure DevOps project created"
}
