
data "azuredevops_project" "this" {
  name = var.ecp_azure_devops_project_name
}

data "azuredevops_git_repository" "this" {
  project_id = data.azuredevops_project.this.id
  name       = var.ecp_azure_devops_repository_name
}

# data "azuredevops_serviceendpoint_azurerm" "this" { 
#   project_id = data.azuredevops_project.this.id
#   name       = "Azure-${local.resource_group.name}-ServiceConnection"
# }

resource "azuredevops_build_definition" "pipelines" {
  for_each = toset(var.ado_yaml_pipeline_artefact_names)

  project_id = data.azuredevops_project.this.id
  name       = var.ado_yaml_pipeline_definitions[each.key].nameElement
  path       = coalesce(var.ado_yaml_pipeline_definitions[each.key].path, "\\")

  agent_pool_name = coalesce(var.ado_yaml_pipeline_definitions[each.key].queue.name, "Azure Pipelines")
  #  A list of variable group IDs (integers) 
  variable_groups = null # []
  variable {
    name  = "environment"
    value = "dev"
  }
  features {
    skip_first_run = coalesce(var.ado_yaml_pipeline_definitions[each.key].skipFirstRun, true)
  }
  queue_status            = coalesce(var.ado_yaml_pipeline_definitions[each.key].queueStatus, "enabled")
  job_authorization_scope = coalesce(var.ado_yaml_pipeline_definitions[each.key].jobAuthorizationScope, "projectCollection")

  ci_trigger {
    use_yaml = true
    # forks {
    #   enabled = false
    #   share_secrets = false
    # }
  }

  repository {
    repo_id             = data.azuredevops_git_repository.this.id
    repo_type           = coalesce(var.ado_yaml_pipeline_definitions[each.key].repository.type, "TfsGit")
    branch_name         = coalesce(var.ado_yaml_pipeline_definitions[each.key].repository.defaultBranch, "refs/heads/main")
    yml_path            = var.ado_yaml_pipeline_definitions[each.key].process.yamlFilename
    report_build_status = try(var.ado_yaml_pipeline_definitions[each.key].repository.properties.reportBuildStatus, true)
  }

  # Variable Groups
  # dynamic "variable_groups" {
  #   for_each = each.value.variable_group_ids != null ? each.value.variable_group_ids : []
  #   content {
  #     variable_groups.value
  #   }
  # }

  # # Variables
  # dynamic "variable" {
  #   for_each = each.value.variables != null ? each.value.variables : {}
  #   content {
  #     name           = variable.key
  #     value          = variable.value.value
  #     is_secret      = try(variable.value.is_secret, false)
  #     allow_override = try(variable.value.allow_override, true)
  #   }
  # }

  # Features


  # Queue settings
  # dynamic "queue" {
  #   for_each = each.value.agent_pool_name != null ? [1] : []  
  #   content {
  #     agent_pool_name = each.value.agent_pool_name
  #   }
  # }

  # schedules {}

  depends_on = [
    azuredevops_environment.ecp,
    azuredevops_build_folder.two
  ]
}

# # Build Definition Permissions
# resource "azuredevops_build_definition_permissions" "pipeline_permissions" {
#   for_each = {
#     for key, pipeline in var.ado_pipeline_definitions : key => pipeline
#     if pipeline.permissions != null
#   }

#   project_id          = data.azuredevops_project.this.id
#   principal           = each.value.permissions.principal
#   build_definition_id = azuredevops_build_definition.pipelines[each.key].id
#   permissions         = each.value.permissions.permissions
# }
locals {
  pip_env_list = [
    for pip_item in var.ado_yaml_pipeline_artefact_names : {
      for env_key, env_value in local.ecp_pipeline_environments :
      "${pip_item}-${env_key}" => {
        pip_item  = pip_item
        env_key   = env_key
        env_value = env_value
      }
    }
  ]
  pip_env_object = zipmap(
    flatten([for entry, attr in local.pip_env_list : keys(attr)]),
    flatten([for entry, attr in local.pip_env_list : values(attr)])
  )
}

# # Environment Resource Authorization
resource "azuredevops_pipeline_authorization" "ecp_environment" {
  # for_each = toset(var.ado_yaml_pipeline_artefact_names)

  for_each = local.pip_env_object

  project_id          = data.azuredevops_project.this.id
  resource_id         = azuredevops_environment.ecp[each.value.env_key].id
  type                = "environment"
  pipeline_id         = azuredevops_build_definition.pipelines[each.value.pip_item].id
  pipeline_project_id = null
}

# # Service Connection Authorization  
# resource "azuredevops_resource_authorization" "service_connection_auth" {
#   for_each = {
#     for key, pipeline in var.ado_pipeline_definitions : key => pipeline
#     if var.create_service_connection && pipeline.authorize_service_connection == true
#   }

#   project_id    = data.azuredevops_project.this.id
#   resource_id   = azuredevops_serviceendpoint_azurerm.pipeline_service_connection[0].id
#   definition_id = azuredevops_build_definition.pipelines[each.key].id
#   authorized    = true
#   type          = "endpoint"
# }
