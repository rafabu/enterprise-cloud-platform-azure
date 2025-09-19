# import {
#   to = azuredevops_git_repository.this
#   id = "<<<repository_id>>>"
# }

# add additional repository, if name does not match project name
resource "azuredevops_git_repository" "non_default" {
  for_each = toset(var.ecp_azure_devops_repository_name == var.ecp_azure_devops_project_name ? [] : ["do"])

  project_id     = azuredevops_project.this.id
  name           = var.ecp_azure_devops_repository_name
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

########### Default Repository ###########
data "azuredevops_git_repository" "default" {
  project_id = azuredevops_project.this.id
  name       = var.ecp_azure_devops_project_name
}

# if non-default repo is used, disable the original one
# import {
#   to = azuredevops_git_repository.default_disable
#   id = "${azuredevops_project.this.id}/${var.ecp_azure_devops_project_name}"
# }

# resource "azuredevops_git_repository" "default_disable" {
#   project_id = azuredevops_project.this.id
#   name       = var.ecp_azure_devops_project_name

#   disabled = var.ecp_azure_devops_repository_name == var.ecp_azure_devops_project_name ? false : true
#   initialization {
#     init_type = "Clean"
#   }

#   lifecycle {
#     ignore_changes = [
#       # Ignore changes to initialization to support importing existing repositories
#       # Given that a repo now exists, either imported into terraform state or created by terraform,
#       # we don't care for the configuration of initialization against the existing resource
#       initialization,
#     ]
#   }
# }

locals {
  git_repository = merge(
    data.azuredevops_git_repository.default,
    azuredevops_git_repository.non_default["do"]
  )
}
