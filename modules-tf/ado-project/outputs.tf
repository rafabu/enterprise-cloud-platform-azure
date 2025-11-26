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

output "azuredevops_git_repositories" {
  value = {
    for r in local.git_repositories : r.name => {
      id             = r.id
      name           = r.name
      default_branch = r.default_branch
      url            = r.url
      web_url        = r.web_url
    }
  }
}
