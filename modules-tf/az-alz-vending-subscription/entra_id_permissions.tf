module "entra_id_permissions" {
  source = "./modules/role_permission_pair"

  for_each = local.entra_roles_with_permission

  role_display_name                    = replace(each.value.use_pim ? "${local.name_template_permission_managed}-privileged" : local.name_template_role_assignable, "/<(?:role|permission)>/", each.value.name_suffix)
  role_eligible_display_name           = replace(each.value.use_pim ? "${local.name_template_role_assignable}-eligible" : "", "/<(?:role|permission)>/", each.value.name_suffix)
  permission_display_name              = replace(local.name_template_permission_managed, "/<(?:permission)>/", each.value.name_suffix)
  role_member_object_ids               = each.value.role_member_object_ids
  use_pim                              = each.value.use_pim
  pim_permanent_role_member_object_ids = each.value.pim_permanent_role_member_object_ids
}


output "zzz_entra_id_permissions" {
  value       = { for k, v in module.entra_id_permissions : k => v }
  description = "The Entra ID groups created for the role-permission pairs."
}