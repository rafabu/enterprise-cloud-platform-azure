resource "azuredevops_variable_group" "mpool_variablegroup" {
  name         = local.variable_group_name
  description  = "Variable group for ${var.ecp_azure_devops_project_name} project. Get important information for your project automation from here. This variable group is automatically created and maintained by the ECP DevOps module."
  project_id   = local.azure_devops_project.project_id
  allow_access = true

  variable {
    name  = "ecp_configuration_repo_url"
    value = "https://${var.ecp_configuration_repo}"
  }

  variable {
    name  = "ecp_configuration_repo_ref"
    value = var.ecp_configuration_repo_version
  }

  variable {
    name  = "ecp_configuration_repo_deployment_root_path"
    value = var.ecp_configuration_repo_deployment_root_path
  }

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
    value = azapi_resource.managed_devops_pool.name
  }
  variable {
    name = "ecp_ado_agent_pool_azure_images"
    value = join(", ", [
      for img in try(azapi_resource.managed_devops_pool.body.properties.fabricProfile.images, []) : img.wellKnownImageName
    ])
  }
  dynamic "variable" {
    for_each = local.ado_wid_permission_objects
    content {
      name  = "ecp_ado_service_connection_azure_${variable.key}"
      value = azuredevops_serviceendpoint_azurerm.mpool[variable.key].service_endpoint_name
    }
  }
  dynamic "variable" {
    for_each = local.ado_wid_permission_objects
    content {
      name = "ecp_ado_service_connection_azure_${variable.key}_serviceprincipal"
      value = jsonencode(
        {
          object_id    = local.workload_identity_objects[variable.key].object_id
          tenant_id    = local.workload_identity_objects[variable.key].tenant_id
          client_id    = local.workload_identity_objects[variable.key].client_id
          display_name = local.workload_identity_objects[variable.key].display_name
          type         = local.workload_identity_objects[variable.key].type
        }
      )
    }
  }
  variable {
    name = "ecp_tf_backend_levels"
    value = join(", ", [
      for key, val in var.backend_storage_accounts : key
    ])
  }
  # output details about backend resources
  dynamic "variable" {
    for_each = var.backend_storage_accounts
    content {
      name = "ecp_tf_backend_storage_azure_${variable.key}"
      value = jsonencode(
        {
          name                 = variable.value.name
          fqdn                 = try(variable.value.primary_blob_endpoint.fqdn, "${variable.value.name}.blob.core.windows.net")
          private_ip_address   = try(variable.value.private_endpoint_blob.private_ip_address, null)
          ecp_level            = variable.value.ecp_level
          tf_backend_container = try(variable.value.tf_backend_container, "tfstate")
          subscription_id      = variable.value.subscription_id
          resource_group_name  = variable.value.resource_group_name
        }
      )
    }
  }
}

resource "azuredevops_pipeline_authorization" "mpool_variablegroup" {
  project_id  = local.azure_devops_project.project_id
  resource_id = azuredevops_variable_group.mpool_variablegroup.id
  type        = "variablegroup"
}
