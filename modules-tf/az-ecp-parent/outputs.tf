output "ecp_environment_name" {
  description = "The name of the ECP environment"
  value       = var.ecp_environment_name
}

output "ecp_deployment_parent_management_group_name" {
  value = azurerm_management_group.ecp_deployment_parent.name
}

output "ecp_deployment_parent_management_group_id" {
  value = azurerm_management_group.ecp_deployment_parent.id
}
