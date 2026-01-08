
locals {
  # do <TERRAFORM_VARIABLE:(.+)> replacement in pipeline definitions
  ado_yaml_pipeline_definitions_normalized = {
    for a in var.ado_yaml_pipeline_artefact_names : a =>
    yamldecode(
      replace(
        replace(
          replace(
            replace(
              yamlencode(var.ado_yaml_pipeline_definitions[a]),
              "/${local.matchpattern_terraform_variable_ecp_environment_name}/",
              var.ecp_environment_name
            ),
            "/${local.matchpattern_terraform_variable_ecp_azure_devops_project_name}/",
            var.ecp_azure_devops_project_name
          ),
          "/${local.matchpattern_terraform_variable_ecp_azure_devops_repository_name}/",
          var.ecp_azure_devops_repository_name
        ),
        "/${local.matchpattern_terraform_variable_ecp_azure_devops_pool_name}/",
        var.ecp_azure_devops_pool_name
      )
    )
  }
}

data "azuredevops_project" "this" {
  name = var.ecp_azure_devops_project_name
}

data "azuredevops_git_repository" "this" {
  project_id = data.azuredevops_project.this.id
  name       = var.ecp_azure_devops_repository_name
}

resource "azuredevops_build_definition" "pipelines" {
  for_each = toset(var.ado_yaml_pipeline_artefact_names)

  project_id = data.azuredevops_project.this.id
  name       = local.ado_yaml_pipeline_definitions_normalized[each.key].nameElement
  path       = coalesce(local.ado_yaml_pipeline_definitions_normalized[each.key].path, "\\")

  agent_pool_name = coalesce(try(local.ado_yaml_pipeline_definitions_normalized[each.key].queue.name, ""), "Azure Pipelines")

  features {
    skip_first_run = coalesce(local.ado_yaml_pipeline_definitions_normalized[each.key].skipFirstRun, true)
  }
  queue_status            = coalesce(local.ado_yaml_pipeline_definitions_normalized[each.key].queueStatus, "enabled")
  job_authorization_scope = coalesce(local.ado_yaml_pipeline_definitions_normalized[each.key].jobAuthorizationScope, "projectCollection")

  ci_trigger {
    use_yaml = true
    # forks {
    #   enabled = false
    #   share_secrets = false
    # }
  }

  repository {
    repo_id             = data.azuredevops_git_repository.this.id
    repo_type           = coalesce(local.ado_yaml_pipeline_definitions_normalized[each.key].repository.type, "TfsGit")
    branch_name         = coalesce(local.ado_yaml_pipeline_definitions_normalized[each.key].repository.defaultBranch, "refs/heads/main")
    yml_path            = local.ado_yaml_pipeline_definitions_normalized[each.key].process.yamlFilename
    report_build_status = try(local.ado_yaml_pipeline_definitions_normalized[each.key].repository.properties.reportBuildStatus, true)
  }

  variable_groups = local.ado_yaml_pipeline_definitions_normalized[each.key].variableGroups != null ? [
    for vg in try(local.ado_yaml_pipeline_definitions_normalized[each.key].variableGroups, []) : vg.id
  ] : null

  dynamic "variable" {
    for_each = local.ado_yaml_pipeline_definitions_normalized[each.key].variables != null ? local.ado_yaml_pipeline_definitions_normalized[each.key].variables : {}
    content {
      name           = variable.key
      value          = variable.value.value
      is_secret      = try(variable.value.isSecret, false)
      allow_override = try(variable.value.allowOverride, true)
    }
  }

  depends_on = [
    azuredevops_environment.ecp,
    azuredevops_build_folder.two
  ]
}

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
  for_each = local.pip_env_object

  project_id          = data.azuredevops_project.this.id
  resource_id         = azuredevops_environment.ecp[each.value.env_key].id
  type                = "environment"
  pipeline_id         = azuredevops_build_definition.pipelines[each.value.pip_item].id
  pipeline_project_id = null
}
