locals {
  # Generate unique trigger based on commits and force sync flag
  sync_trigger = var.sync_enabled ? (
    var.force_sync ? 
    "${local.submodule_current_commit}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" :
    "${data.azuredevops_git_repository.target.default_branch}-${local.submodule_current_commit}"
  ) : "disabled"
  
  # PowerShell script command with parameters for local submodule sync
  sync_script_command = "pwsh -File ${path.module}/scripts/sync-repository.ps1 -LocalSubmodulePath '${var.local_submodule_path}' -AdoOrg '${var.ecp_azure_devops_organization_name}' -AdoProject '${var.ecp_azure_devops_project_name}' -AdoRepo '${var.ecp_azure_devops_repository_name}' -TargetBranch '${var.ecp_azure_devops_target_branch}' -ForceSync '$$${var.force_sync}'"
  
  # Local submodule commit hash for change detection
  submodule_commit_hash = try(file("${var.local_submodule_path}/.git/refs/heads/main"), "unknown")
}