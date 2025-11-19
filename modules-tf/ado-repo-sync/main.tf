data "azuredevops_git_repository" "target" {
  project_id = data.azuredevops_project.this.id
  name       = var.ecp_azure_devops_repository_name
}

data "azuredevops_project" "this" {
  name = var.ecp_azure_devops_project_name
}

# run git command to get current commit of submodule
#     git rev-parse HEAD
data "external" "git_submodule_head_commit" {
  program     = ["pwsh", "-NoLogo", "-NonInteractive", "-ExecutionPolicy", "RemoteSigned", "-Command", "$commit = git rev-parse HEAD; @{commit=$commit} | ConvertTo-Json -Compress"]
  working_dir = var.local_submodule_path
  query       = {}
}

resource "terraform_data" "ado_repo_sync" {
  count = var.sync_enabled ? 1 : 0

  triggers_replace = {
    # Trigger on local submodule commit changes
    git_submodule_commit = data.external.git_submodule_head_commit.result.commit
    # Trigger on Azure DevOps commit changes (in case of external updates)
    ado_default_branch = data.azuredevops_git_repository.target.default_branch
    # Force sync trigger
    force_sync = var.force_sync ? plantimestamp() : "disabled"
    # Configuration changes
    config_hash = md5(jsonencode({
      submodule_path = var.local_submodule_path
      ado_repo       = var.ecp_azure_devops_repository_name
      target_branch  = var.ecp_azure_devops_target_branch
    }))
    script_hash = filemd5("${path.module}/scripts/sync-repository.ps1")
  }

  provisioner "local-exec" {
    interpreter = ["pwsh", "-NoLogo", "-NonInteractive", "-ExecutionPolicy", "RemoteSigned", "-Command"]
    command     = "& '${path.module}/scripts/sync-repository.ps1' -LocalSubmodulePath '${var.local_submodule_path}' -AdoOrg '${var.ecp_azure_devops_organization_name}' -AdoProject '${var.ecp_azure_devops_project_name}' -AdoRepo '${var.ecp_azure_devops_repository_name}' -TargetBranch '${var.ecp_azure_devops_target_branch}' -ForceSync ([bool]$${var.force_sync})"

    environment = {}
  }

  depends_on = [
    data.azuredevops_git_repository.target
  ]
}
