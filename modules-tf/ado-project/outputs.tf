output "azuredevops_project" {
  value = {
    id          = azuredevops_project.this.id
    name        = azuredevops_project.this.name
    description = azuredevops_project.this.description
  }
}

output "all_azuredevops_projects" {
  value = {
    for p in try(data.azuredevops_projects.all.projects, []) : p["project_id"] => {
      id    = p["project_id"]
      name  = p["name"]
      state = p["state"]
    }
  }
}


output "azuredevops_git_repository" {
  value = {
    id             = local.git_repository.id
    name           = local.git_repository.name
    default_branch = local.git_repository.default_branch
    url            = local.git_repository.url
    web_url        = local.git_repository.web_url
  }
}
