output "parent_management_group_name" {
  value = azurerm_management_group.ecp_deployment_parent.name
}

output "parent_management_group_id" {
  value = azurerm_management_group.ecp_deployment_parent.id
}

output "role_group_contributor_name" {
  value = azuread_group_without_members.contributor_role.display_name
}

output "role_group_contributor_object_id" {
  value = azuread_group_without_members.contributor_role.object_id
}

output "role_group_reader_name" {
  value = azuread_group_without_members.reader_role.display_name
}

output "role_group_reader_object_id" {
  value = azuread_group_without_members.reader_role.object_id
}
