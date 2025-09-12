# import {
#   to = azuredevops_project.this
#   id = "<<<project_id>>>"
# }
data "azuredevops_projects" "all" {
}


resource "azuredevops_project" "this" {
  name               = var.ecp_azure_devops_project_name
  visibility         = "private"
  description        = "Enterprise Cloud Platform (ECP) Automation Repository"
  version_control    = "Git"
  work_item_template = "Agile"

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
