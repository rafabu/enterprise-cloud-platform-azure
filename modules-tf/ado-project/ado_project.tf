data "azuredevops_projects" "all" {
}


resource "azuredevops_project" "this" {
  name               = var.ecp_azure_devops_project_name
  visibility         = "private"
  description        = "Enterprise Cloud Platform (ECP) Automation Repository"
  version_control    = "Git"
  work_item_template = "Agile"

  features = {
    boards       = "disabled",
    repositories = "disabled",
    pipelines    = "disabled",
    testplans    = "disabled",
    artifacts    = "disabled"
  }

  lifecycle {
    ignore_changes = [
      features
    ]
  }
}

resource "azuredevops_project_features" "this" {
  project_id = azuredevops_project.this.id

  features = {
    boards       = "disabled",
    repositories = "enabled",
    pipelines    = "enabled",
    testplans    = "disabled",
    artifacts    = "disabled"
  }
}

# delete default repository (unless requested)
data "azuredevops_git_repositories" "project" {
  project_id     = azuredevops_project.this.id
  name           = null
  include_hidden = true
}

locals {
  default_git_repository = try([
    for repo in data.azuredevops_git_repositories.project.repositories : repo
    if repo.name == var.ecp_azure_devops_project_name
  ][0], [])
}

resource "terraform_data" "git_repository_default_delete" {
  for_each = toset(contains([var.ecp_azure_devops_repository_names], var.ecp_azure_devops_project_name) == false ? ["do"] : [])

  triggers_replace = {
    project_id = azuredevops_project.this.id
  }

  provisioner "local-exec" {
    when        = create
    command     = length(try(local.default_git_repository.id, "")) > 0 ? "az config set extension.use_dynamic_install=yes_without_prompt; az repos delete --id ${try(local.default_git_repository.id, "")} --yes --organization ${data.azuredevops_client_config.this.organization_url} --project ${local.default_git_repository.project_id}" : "echo keeping default repo"
    interpreter = ["pwsh", "-Command"]
  }

  depends_on = [ azuredevops_git_repository.non_default ]
}
