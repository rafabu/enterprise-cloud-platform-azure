output "resource_group" {
  description = "The ID of the resource group"
  value = {
    # id       = azurerm_resource_group.lp.id
    # name     = azurerm_resource_group.lp.name
    # location = azurerm_resource_group.lp.location
    id       = azapi_resource.lp_rg.id
    name     = azapi_resource.lp_rg.name
    location = azapi_resource.lp_rg.location
  }
}

output "ecp_environment_name" {
  description = "Name of the ECP environment (used for naming resources)"
  value       = var.ecp_environment_name
}

output "ecp_azure_devops_automation_repository_name" {
  description = "Name of the ECP Azure DevOps automation repository"
  value       = var.ecp_azure_devops_automation_repository_name
}

output "ecp_azure_devops_configuration_repository_name" {
  description = "Name of the ECP Azure DevOps configuration repository"
  value       = var.ecp_azure_devops_configuration_repository_name
}

output "ecp_configuration_repo_deployment_root_path" {
  description = "Root path in ECP.Configuration repository where environment configurations are stored"
  value       = var.ecp_configuration_repo_deployment_root_path
}

output "azuredevops_organization_name" {
  description = "name of Azure DevOps organization"
  value       = var.ecp_azure_devops_organization_name
}
