module "entra_id_permissions" {
  source = "./modules/role_permission_pair"

  for_each = local.entra_roles_with_permission

  role_display_name          = replace(each.value.use_pim ? "${local.name_template_permission_managed}-privileged" : local.name_template_role_assignable, "/<(?:role|permission)>/", each.value.name_suffix)
  role_eligible_display_name = replace(each.value.use_pim ? "${local.name_template_role_assignable}-eligible" : "", "/<(?:role|permission)>/", each.value.name_suffix)
  permission_display_name    = replace(local.name_template_permission_managed, "/<(?:permission)>/", each.value.name_suffix)
  role_member_object_ids     = each.value.role_member_object_ids
  role_owner_object_ids      = each.value.role_owner_object_ids
  use_pim                    = each.value.use_pim

  permanent_permission_member_object_ids = each.value.permanent_permission_member_object_ids

  vending_managed_identity_object_id = var.ecp_azure_deployment_service_principal_object_id
}
