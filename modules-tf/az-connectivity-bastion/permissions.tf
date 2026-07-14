# reader permission (every bastion user needs reader to use it (plus access to the VMs they want to connect to)
resource "azuread_group_without_members" "bastion_reader" {
  display_name            = replace(local.name_template_permission_managed, "<permission>", "bastionhost-reader")
  prevent_duplicate_names = true
  security_enabled        = true

  lifecycle {
    ignore_changes = [
      owners
    ]
  }
}

# Generate unique UUIDs for role assignments (required for consistent naming)
resource "random_uuid" "bastion_reader_role" {
  for_each = local.hub_locations

  keepers = {
    bastion_id = azapi_resource.bastion[each.key].id
    group_id   = azuread_group_without_members.bastion_reader.object_id
    role_id    = "acdd72a7-3385-48ef-bd42-f606fba81ae7"
  }
}

# RBAC: Grant bastion_reader group Reader access on all bastion hosts
resource "azapi_resource" "bastion_reader_role_assignment" {
  for_each = local.hub_locations

  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = random_uuid.bastion_reader_role[each.key].result
  parent_id = azapi_resource.bastion[each.key].id

  body = {
    properties = {
      principalId      = azuread_group_without_members.bastion_reader.object_id
      roleDefinitionId = "/subscriptions/${var.ecp_connectivity_subscription_id}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
      principalType    = "Group"
    }
  }
}



