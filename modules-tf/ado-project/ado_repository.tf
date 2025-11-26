# add additional repository, if name does not match project name

moved {
  from = azuredevops_git_repository.non_default["do"]
  to   = azuredevops_git_repository.non_default["ECP.Automation"]
}
resource "azuredevops_git_repository" "non_default" {
  # for_each = toset(var.ecp_azure_devops_repository_name != var.ecp_azure_devops_project_name ? ["do"] : [])
  for_each = toset([
    for r in var.ecp_azure_devops_repository_names : r
    if r != var.ecp_azure_devops_project_name
  ])

  project_id = azuredevops_project.this.id
  # name           = var.ecp_azure_devops_repository_name
  name           = each.key
  default_branch = "refs/heads/main"

  initialization {
    init_type = "Clean"
  }

  depends_on = [
    azuredevops_project_features.this
  ]

  lifecycle {
    ignore_changes = [
      # Ignore changes to initialization to support importing existing repositories
      # Given that a repo now exists, either imported into terraform state or created by terraform,
      # we don't care for the configuration of initialization against the existing resource
      initialization,
    ]
  }
}

resource "time_sleep" "git_repository_non_default_destroy_helper_destroy_delay" {
  # destroy only: after recreating the default repo, wait a little while before destroying the non-default repo
  #     to allow Azure DevOps to catch up
  # for_each = toset(var.ecp_azure_devops_repository_name != var.ecp_azure_devops_project_name ? ["do"] : [])
  for_each = toset(contains([var.ecp_azure_devops_repository_names], var.ecp_azure_devops_project_name) == false ? ["do"] : [])

  destroy_duration = "15s" # Wait 15' ONLY on destroy

  depends_on = [
    azuredevops_git_repository.non_default
  ]
}

# before being able to delete non-default repository and the project, the default repository needs to exist (again)
resource "terraform_data" "git_repository_non_default_destroy_helper" {
  #for_each = toset(var.ecp_azure_devops_repository_name != var.ecp_azure_devops_project_name ? ["do"] : [])
  for_each = toset(contains([var.ecp_azure_devops_repository_names], var.ecp_azure_devops_project_name) == false ? ["do"] : [])

  input = {
    default_repository_name = var.ecp_azure_devops_project_name
    organization_url        = data.azuredevops_client_config.this.organization_url
    project_id              = azuredevops_project.this.id
  }

  triggers_replace = {
    repository_id = azuredevops_git_repository.non_default[each.key].id
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "az config set extension.use_dynamic_install=yes_without_prompt; az repos create --name ${self.output.default_repository_name} --organization ${self.output.organization_url} --project ${self.output.project_id}"
    interpreter = ["pwsh", "-Command"]
  }

  depends_on = [
    azuredevops_git_repository.non_default,
    time_sleep.git_repository_non_default_destroy_helper_destroy_delay
  ]
}

########### Default Repository ###########
#     this is just for output
data "azuredevops_git_repository" "default" {
  # for_each = toset(var.ecp_azure_devops_repository_name == var.ecp_azure_devops_project_name ? ["do"] : [])
  for_each = toset(contains([var.ecp_azure_devops_repository_names], var.ecp_azure_devops_project_name) == false ? ["do"] : [])

  project_id = azuredevops_project.this.id
  name       = var.ecp_azure_devops_project_name
}

locals {
  git_repositories = merge(
    contains([var.ecp_azure_devops_repository_names], var.ecp_azure_devops_project_name) == false ? {
      "${data.azuredevops_git_repository.default["do"].name}" = data.azuredevops_git_repository.default["do"]
    } : {},
    try(azuredevops_git_repository.non_default, {})
  )
}
