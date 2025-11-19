
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
  for_each = toset(var.ado_yaml_pipeline_names)

  project_id = data.azuredevops_project.this.id
  name       = var.ado_yaml_pipeline_definitions[each.key].nameElement
  path       = coalesce(var.ado_yaml_pipeline_definitions[each.key].path, "\\")

  # build_completion_trigger {}

  ci_trigger {
    use_yaml = true
    # forks {
    #   enabled = false
    #   share_secrets = false
    # }
  }

  # pull_request_trigger {
  #   use_yaml = true
  #    forks {
  #     enabled = false
  #     share_secrets = false
  #   }
  # }

  # YAML pipeline definition
  dynamic "repository" {
    for_each = [0]
    content {
      repo_id   = data.azuredevops_git_repository.this.id
      repo_type = "TfsGit"
      # branch_name = "main"
      yml_path            = var.ado_yaml_pipeline_definitions[each.key].yamlFilename
      report_build_status = true
    }
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
  features {
    skip_first_run = coalesce(var.ado_yaml_pipeline_definitions[each.key].skipFirstRun, false)
  }

  # Queue settings
  # dynamic "queue" {
  #   for_each = each.value.agent_pool_name != null ? [1] : []  
  #   content {
  #     agent_pool_name = each.value.agent_pool_name
  #   }
  # }

  # schedules {}
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

# # Environment for deployment pipelines
# resource "azuredevops_environment" "deployment_environments" {
#   for_each = {
#     for key, pipeline in var.ado_pipeline_definitions : key => pipeline
#     if pipeline.create_environment == true
#   }

#   project_id  = data.azuredevops_project.this.id
#   name        = "${data.azurecaf_name.pipeline[each.key].result}-env"
#   description = "Environment for ${data.azurecaf_name.pipeline[each.key].result} pipeline deployments"
# }

# # Environment Resource Authorization
# resource "azuredevops_resource_authorization" "environment_auth" {
#   for_each = {
#     for key, pipeline in var.ado_pipeline_definitions : key => pipeline
#     if pipeline.create_environment == true && var.create_service_connection
#   }

#   project_id    = data.azuredevops_project.this.id
#   resource_id   = azuredevops_environment.deployment_environments[each.key].id
#   definition_id = azuredevops_build_definition.pipelines[each.key].id
#   authorized    = true
#   type          = "environment"
# }

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
