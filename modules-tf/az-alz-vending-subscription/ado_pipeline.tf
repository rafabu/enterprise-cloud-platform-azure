
data "azuredevops_project" "ecp" {
  name = var.ecp_azure_devops_project_name
}

data "azuredevops_git_repository" "ecp" {
  project_id = data.azuredevops_project.ecp.id
  name       = var.ecp_azure_devops_repository_name
}

resource "azuredevops_build_definition" "lz_deployment" {

  project_id = data.azuredevops_project.ecp.id
  name       = local.devops_landing_zone_deployment_pipeline_name
  path       = local.devops_landing_zone_deployment_pipeline_path

  agent_pool_name = var.ecp_azure_devops_managed_devops_pool_name

  features {
    skip_first_run = true
  }
  queue_status            = "enabled"
  job_authorization_scope = "projectCollection"

  ci_trigger {
    use_yaml = true
    # forks {
    #   enabled = false
    #   share_secrets = false
    # }
  }

  repository {
    repo_id             = data.azuredevops_git_repository.ecp.id
    repo_type           = "TfsGit"
    branch_name         = "refs/heads/main"
    yml_path            = "pipelines-iaih-d9-ado/ecp-tg-deploy-landing-zone.yaml"
    report_build_status = true
  }

  variable_groups = null

  variable {
    name           = "terragrunt_stack"
    value          = "ai-lz-dev"
    is_secret      = false
    allow_override = false
  }
}

data "azuredevops_environment" "l3" {
  project_id = data.azuredevops_project.ecp.id
  name       = local.devops_landing_zone_environment_name
}

# # Environment Resource Authorization
resource "azuredevops_pipeline_authorization" "environment_l3" {

  project_id          = data.azuredevops_project.ecp.id
  resource_id         = data.azuredevops_environment.l3.id
  type                = "environment"
  pipeline_id         = azuredevops_build_definition.lz_deployment.id
  pipeline_project_id = data.azuredevops_project.ecp.id
}
