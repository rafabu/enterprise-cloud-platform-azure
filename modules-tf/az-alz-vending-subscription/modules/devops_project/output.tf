output "azure_devops_project" {
  value = {
    id          = azuredevops_project.this.id
    name        = azuredevops_project.this.name
    description = azuredevops_project.this.description
    url         = "${data.azuredevops_client_config.current.organization_url}/${azuredevops_project.this.name}"
  }
  description = "The Azure DevOps project created"
}
