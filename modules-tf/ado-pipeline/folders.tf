locals {
  ecp_pipeline_folders = {
    zero = {
      ecp = {
        name        = "ECP"
        description = "Enterprise Cloud Platform (ECP) root folder"
        permissions = []
      }
    }
    one = {
      ecp_environment = {
        name        = local.ecp_environment_name
        parent_key  = "ecp"
        description = "Enterprise Cloud Platform (ECP) environment folder"
        permissions = []
      }
    }
    two = {
      deploy_platform = {
        name        = "deploy_platform"
        parent_key  = "ecp_environment"
        description = "Enterprise Cloud Platform (ECP) deploy platform folder"
        permissions = []
      },
      deploy_workloads = {
        name        = "deploy_workloads"
        parent_key  = "ecp_environment"
        description = "Enterprise Cloud Platform (ECP) deploy workloads folder"
        permissions = []
      },
      insights = {
        name        = "insights"
        parent_key  = "ecp_environment"
        description = "Enterprise Cloud Platform (ECP) insights folder"
        permissions = []
      }
    }
  }
}

# shared folder if more than a single ECP environment is deployed
#     TODO: enhance to create multiple folders if multiple environments are deployed

# resource "azuredevops_build_folder" "zero" {
#   for_each = try(local.ecp_pipeline_folders["zero"], {})

#   project_id  = data.azuredevops_project.this.id
#   path        = "\\${each.value.name}"
#   description = "Enterprise Cloud Platform (ECP) root folder"
# }

resource "azuredevops_build_folder" "one" {
  for_each = try(local.ecp_pipeline_folders["one"], {})

  project_id  = data.azuredevops_project.this.id
  #path        = "${azuredevops_build_folder.zero[each.value.parent_key].path}\\${each.value.name}"
  path        = "\\${local.ecp_pipeline_folders["zero"]["ecp"].name}\\${each.value.name}"
  description = "Enterprise Cloud Platform (ECP) environment folder"
}

resource "azuredevops_build_folder" "two" {
  for_each = try(local.ecp_pipeline_folders["two"], {})

  project_id  = data.azuredevops_project.this.id
  path        = "${azuredevops_build_folder.one[each.value.parent_key].path}\\${each.value.name}"
  description = "Enterprise Cloud Platform (ECP) platform folder"
}
