module "devops_project" {
  source = "./modules/devops_project"

  for_each = toset(var.azure_devops_project_name != null ? ["this"] : [])

  azure_devops_project_name        = var.azure_devops_project_name
  azure_devops_project_description = var.azure_devops_project_description
}


output "azure_devops_project" {
  value       = module.devops_project.azure_devops_project
  description = "The Azure DevOps project created"
}