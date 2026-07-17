output "role_group_object_id"  {
  value       = azuread_group.role.object_id
  description = "The object ID of the Entra ID group \"role\"."
}

output "permission_group_object_id"  {
  value       = azuread_group.permission.object_id
  description = "The object ID of the Entra ID group \"permission\"."
}