resource "azuredevops_variable_group" "mpool_variablegroup" {
  name         = local.variable_group_name
  description  = "Variable group for ${var.ecp_azure_devops_project_name} project. Get important information for your project automation from here. This variable group is automatically created and maintained by the ECP DevOps module."
  project_id   = data.azuredevops_project.ecp.id
  allow_access = true

  variable {
    name  = "ecp_environment_name"
    value = var.azure_resource_name_elements.prefixes[0]
  }

  variable {
    name  = "ecp_launchpad_azure_subscription_id"
    value = data.azurerm_client_config.this.subscription_id
  }
  variable {
    name  = "ecp_entra_tenant_id"
    value = data.azurerm_client_config.this.tenant_id
  }
  variable {
    name  = "ecp_ado_agent_pool_azure"
    value = module.managed_devops_pool.name
  }

  variable {
    name = "ecp_ado_agent_pool_azure_images"
    value = join(", ", [
      for img in try(module.managed_devops_pool.resource.body.properties.fabricProfile.images, []) : img.wellKnownImageName
    ])
  }

  dynamic "variable" {
    for_each = local.ado_wid_permission_objects
    content {
      name  = "ecp_ado_service_connection_azure_${variable.key}"
      value = azuredevops_serviceendpoint_azurerm.mpool[variable.key].service_endpoint_name
    }
  }
}

resource "azuredevops_pipeline_authorization" "mpool_variablegroup" {
  project_id  = data.azuredevops_project.ecp.id
  resource_id = azuredevops_variable_group.mpool_variablegroup.id
  type        = "variablegroup"
}
