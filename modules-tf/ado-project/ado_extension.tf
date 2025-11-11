# ms-devlabs.custom-terraform-tasks
# - TerraformInstaller@1 (ms-devlabs.custom-terraform-tasks.TerraformInstaller@1)
# - TerraformTask@5 (ms-devlabs.custom-terraform-tasks.TerraformTask@5)
resource "azuredevops_extension" "custom_terraform_tasks" {
  extension_id = "custom-terraform-tasks"
  publisher_id = "ms-devlabs"
}

# JaydenMaalouf.terraform-output
# - TerraformOutput@1 (JaydenMaalouf.terraform-output.TerraformOutput@1)
resource "azuredevops_extension" "terraform_output" {
  extension_id = "terraform-output"
  publisher_id = "JaydenMaalouf"
}