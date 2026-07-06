module "devops_project" {
  source = "./modules/devops_project"

  for_each = toset(var.azure_devops_project_name != null ? ["this"] : [])

  azure_devops_project_name        = var.azure_devops_project_name
  azure_devops_project_description = var.azure_devops_project_description

  resource_group_id       = azapi_resource.resource_group_management.id
  resource_group_location = azapi_resource.resource_group_management.location
  resource_group_tags     = azapi_resource.resource_group_management.tags

  # UAMI does not (yet) exist in provider DS - just rename the RG one...
  managed_identity_name            = replace(data.azurecaf_name.rg.result, "-rg-", "-id-")

  service_connection_name = replace(data.azurecaf_name.rg.result, "-rg-", "-srv-conn-")
  variable_group_name = local.devops_variable_group_name
  
  # Entra Groups
  owner_permission_group_object_id = module.entra_id_permissions["lz-owner"].permission_group_object_id
  user_permission_group_object_id = module.entra_id_permissions["lz-user"].permission_group_object_id

  shared_agent_pool_name = var.ecp_azure_devops_managed_devops_pool_name
}

output "azure_devops_project" {
  value       = module.devops_project
  description = "The Azure DevOps project created"
}
