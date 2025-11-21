resource "azuredevops_serviceendpoint_azurerm" "mpool" {
  for_each = local.ado_wid_permission_objects

  project_id            = local.azure_devops_project.project_id
  service_endpoint_name = "spc-${each.key}-${data.azurerm_management_group.ecp_root_parent.name}"
  description           = "Managed by ECP DevOps"

  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"

  credentials {
    serviceprincipalid = local.workload_identity_objects[each.key].client_id
  }
  azurerm_spn_tenantid      = data.azurerm_client_config.this.tenant_id
  azurerm_subscription_id   = null # data.azurerm_subscription.launchpad.subscription_id
  azurerm_subscription_name = null # data.azurerm_subscription.launchpad.display_name
  # using management group assignment leads to failing Azure DevOps service connection "verify" results
  #     if terraform's management_group id is used; must use name property instead
  azurerm_management_group_id   = data.azurerm_management_group.ecp_root_parent.name
  azurerm_management_group_name = data.azurerm_management_group.ecp_root_parent.display_name

  lifecycle {
    ignore_changes = all #[
      # description,
    #]
  }

  depends_on = [
    time_sleep.wait_after_user_assigned_identity
  ]
}

resource "time_sleep" "serviceendpoint_azurerm_pre_destroy_delay" {
  # destroy only: after destroying *_federated_identity_credential resources
  #     we have to wait for Entra Id replication or azuredevops_serviceendpoint_azurerm
  #     destroy operation will fail.
  for_each = local.ado_wid_permission_objects

  destroy_duration = "60s" # Wait 1 minute ONLY on destroy

  depends_on = [azuredevops_serviceendpoint_azurerm.mpool]
}

# grant access to service endpoint for all pipelines in the project
# COMMENTED OUT DUE TO PROVIDER INSTABILITY ON LINUX - REPLACED WITH terraform_data IN ado_instable_resources_fix.tf
# resource "azuredevops_pipeline_authorization" "mpool_serviceendpoint" {
#   for_each = local.ado_wid_permission_objects
#
#   project_id  = local.azure_devops_project.project_id
#   resource_id = azuredevops_serviceendpoint_azurerm.mpool[each.key].id
#   type        = "endpoint"
#   # authorized  = true
#
#   lifecycle {
#     ignore_changes = all
#   }
# }
