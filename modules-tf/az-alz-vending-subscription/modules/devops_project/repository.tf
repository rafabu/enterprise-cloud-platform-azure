##################################################    Git Repositories (re-use default)   ##################################################
data "azuredevops_git_repositories" "all-repos" {
  project_id     = azuredevops_project.this.id
  include_hidden = true
}

