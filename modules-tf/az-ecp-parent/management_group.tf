# new Entra tenants will not have been enabled for using management groups
#     TenantBackfill is required. See
#     https://learn.microsoft.com/en-us/cli/azure/account/management-group/tenant-backfill?view=azure-cli-latest
data "external" "ecp_parent_mg_check" {
  program = ["pwsh", "-NoLogo", "-NonInteractive", "-File", "${path.module}/Check-EcpParentManagementGroup.ps1"]

  query = {
    parent_management_group_id           = var.ecp_azure_root_parent_management_group_id
    parent_management_group_display_name = "ECP Root"
    tenant_id                            = data.azurerm_client_config.this.tenant_id
  }
}

resource "time_sleep" "ecp_parent_mg_check" {
  create_duration = data.external.ecp_parent_mg_check.result.parent_management_group_action == "Created" ? "2m" : "1ms"
}

resource "azurerm_management_group" "ecp_deployment_parent" {
  provider = azurerm.launchpad

  name         = "${var.ecp_environment_name}-mg-ecpa-deployment"
  display_name = "Deployment ${var.ecp_environment_name}"

  parent_management_group_id = "/providers/Microsoft.Management/managementGroups/${var.ecp_azure_root_parent_management_group_id}"

  subscription_ids = []

  lifecycle {
    ignore_changes = [
      subscription_ids
    ]
  }

  depends_on = [
    data.external.ecp_parent_mg_check,
    time_sleep.ecp_parent_mg_check
  ]
}

resource "time_sleep" "ecp_deployment_parent" {
  create_duration = "60s"

  depends_on = [
    azurerm_management_group.ecp_deployment_parent
  ]
}

# move ECP platform subscriptions into the ECP deployment parent management group
#     note: this is only happening upon first deployment of the management group 
#           alz deployment will then create the structure and place the subscriptions correctly
locals {
  ecp_platform_subscription_ids = [
    for sub_id in [
      var.ecp_launchpad_subscription_id,
      var.ecp_management_subscription_id,
      var.ecp_connectivity_subscription_id,
      var.ecp_identity_subscription_id,
      var.ecp_security_subscription_id
    ] : sub_id if sub_id != "00000000-0000-0000-0000-000000000000"
  ]
}

resource "azapi_resource_action" "ecp_deployment_parent_subscriptions_move" {
  for_each = toset(local.ecp_platform_subscription_ids)

  type        = "Microsoft.Management/managementGroups@2021-04-01"
  resource_id = azurerm_management_group.ecp_deployment_parent.id
  action      = "subscriptions/${each.key}"
  method      = "PUT"

  depends_on = [
    time_sleep.ecp_deployment_parent
  ]

  lifecycle {
    replace_triggered_by = [
      azurerm_management_group.ecp_deployment_parent.id
    ]
  }
}
