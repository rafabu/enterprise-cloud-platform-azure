# Terraform data resource that triggers when commits change
resource "terraform_data" "repo_sync" {
  count = var.sync_enabled ? 1 : 0
  
  triggers_replace = {
    # Trigger on local submodule commit changes
    submodule_commit = local.submodule_current_commit
    # Fallback: Trigger on content hash changes (slower but more reliable)
    submodule_content = local.submodule_content_hash
    # Trigger on Azure DevOps commit changes (in case of external updates)
    ado_commit = data.azuredevops_git_repository.target.default_branch
    # Force sync trigger
    force_sync = var.force_sync ? plantimestamp() : "disabled"
    # Configuration changes
    config_hash = md5(jsonencode({
      submodule_path = var.local_submodule_path
      ado_repo       = var.ecp_azure_devops_repository_name
      target_branch  = var.ecp_azure_devops_target_branch
    }))
  }
  
  provisioner "local-exec" {
    interpreter = ["pwsh", "-NoLogo", "-NonInteractive", "-ExecutionPolicy", "RemoteSigned", "-file"]
    #command = "./scripts/sync-repository.ps1 -LocalSubmodulePath '${var.local_submodule_path}' -AdoOrg '${var.ecp_azure_devops_organization_name}' -AdoProject '${var.ecp_azure_devops_project_name}' -AdoRepo '${var.ecp_azure_devops_repository_name}' -TargetBranch '${var.ecp_azure_devops_target_branch}' -ForceSync ${var.force_sync}"
    command = "./scripts/sync-repository.ps1"
    
    environment = {
      # Azure DevOps authentication will use the existing az cli context
      # or AZURE_DEVOPS_EXT_PAT environment variable if set
      # AZURE_DEVOPS_EXT_PAT = ""
      # GITHUB_TOKEN = ""
    }
  }
  
  # Optional: Add a provisioner to validate authentication before sync
  # provisioner "local-exec" {
  #   command     = "az devops project show --project '${var.ecp_azure_devops_project_name}' --organization 'https://dev.azure.com/${var.ecp_azure_devops_organization_name}' --output none"
  #   interpreter = ["pwsh", "-Command"]
  # }
  
  depends_on = [
    data.azuredevops_git_repository.target
  ]
}