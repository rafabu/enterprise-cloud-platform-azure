resource "azuredevops_serviceendpoint_azurerm" "mpool" {
  for_each = local.ado_wid_permission_objects

  project_id            = data.azuredevops_project.ecp.id
  service_endpoint_name = "spc-${each.key}-${data.azurerm_management_group.ecp_root_parent.name}"
  description           = "Managed by ECP DevOps"

  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"

  credentials {
    serviceprincipalid = local.workload_identity_service_principals[each.key].client_id
  }
  azurerm_spn_tenantid          = data.azapi_client_config.this.tenant_id
  azurerm_subscription_id       = null # data.azurerm_subscription.workload.subscription_id
  azurerm_subscription_name     = null # data.azurerm_subscription.workload.display_name
  azurerm_management_group_id   = data.azurerm_management_group.ecp_root_parent.id
  azurerm_management_group_name = data.azurerm_management_group.ecp_root_parent.display_name

  lifecycle {
    ignore_changes = [
      description,
    ]
  }
}

# grant access to service endpoint for all pipelines in the project
resource "azuredevops_pipeline_authorization" "mpool" {
  for_each = local.ado_wid_permission_objects

  project_id  = data.azuredevops_project.ecp.id
  resource_id = azuredevops_serviceendpoint_azurerm.mpool[each.key].id
  type        = "endpoint"
  # authorized  = true
}



