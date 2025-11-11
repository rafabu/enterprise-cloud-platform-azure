# ms-devlabs.custom-terraform-tasks
# - TerraformInstaller@1 (ms-devlabs.custom-terraform-tasks.custom-terraform-release-task.TerraformInstaller@1)
# - TerraformTask@5 (ms-devlabs.custom-terraform-tasks.custom-terraform-release-task.TerraformTask@5)
resource "azuredevops_extension" "custom_terraform_tasks" {
  extension_id = "ms-devlabs.custom-terraform-tasks"
  publisher_id = "ms-devlabs"
}

# JaydenMaalouf.terraform-output
# - TerraformOutput@1 (JaydenMaalouf.terraform-output.TerraformOutput@1)
resource "azuredevops_extension" "terraform_output" {
  extension_id = "JaydenMaalouf.terraform-output"
  publisher_id = "JaydenMaalouf"
}