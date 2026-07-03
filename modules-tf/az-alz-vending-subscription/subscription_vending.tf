data "azapi_client_config" "current" {
}



module "vending" {
  source  = "Azure/avm-ptn-alz-sub-vending/azure"
  version = var.avm-ptn-alz-sub-vending_version

  location = var.azure_location

  # resource groups
  resource_group_creation_enabled = true
  resource_groups                 = local.resource_groups

  # role assignment
  role_assignment_enabled = true
  role_assignments = local.role_rbac_assignment_definitions

  # subscription variables
  subscription_alias_enabled                        = false
  subscription_alias_name                           = null
  subscription_billing_scope                        = null
  subscription_display_name                         = local.subscription_display_name
  subscription_register_resource_providers_enabled  = true
  subscription_id                                   = var.subscription_id
  subscription_management_group_association_enabled = true
  subscription_management_group_id                  = var.subscription_management_group_id
  subscription_tags = {
    created_by = "avm-ptn-alz-sub-vending"
  }
  # Whether to update an existing subscription with the supplied tags and display name (in conjunction with subscription_management_group_association_enabled and subscription_id))
  subscription_update_existing = true
  subscription_workload        = null


  network_security_group_enabled = true
  network_security_groups        = local.network_security_groups

  # virtual network variables
  virtual_network_enabled = true
  virtual_networks        = local.virtual_networks

  enable_telemetry = false

  # tags = var.azure_tags
}
