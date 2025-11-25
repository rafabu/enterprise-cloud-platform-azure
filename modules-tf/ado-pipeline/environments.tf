locals {
  ecp_pipeline_environments = {
    ecp_platform_level0 = {
      name        = "${var.ecp_environment_name}_ECP_Platform_Level0"
      description = "Enterprise Cloud Platform (ECP) environment ${var.ecp_environment_name}: Platform Level0"
    }
    ecp_platform_level1 = {
      name        = "${var.ecp_environment_name}_ECP_Platform_Level1"
      description = "Enterprise Cloud Platform (ECP) environment ${var.ecp_environment_name}: Platform Level1"
    }
    ecp_platform_level2 = {
      name        = "${var.ecp_environment_name}_ECP_Platform_Level2"
      description = "Enterprise Cloud Platform (ECP) environment ${var.ecp_environment_name}: Platform Level2"
    }
  }
}

resource "azuredevops_environment" "ecp" {
  for_each = local.ecp_pipeline_environments

  project_id  = data.azuredevops_project.this.id
  name        = each.value.name
  description = try(each.value.description, "")
}
