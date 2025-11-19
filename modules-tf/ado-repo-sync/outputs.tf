output "azure_devops_repository_id" {
  description = "Azure DevOps repository ID"
  value       = data.azuredevops_git_repository.target.id
}

output "azure_devops_repository_url" {
  description = "Azure DevOps repository clone URL"
  value       = data.azuredevops_git_repository.target.remote_url
}

output "local_submodule_path" {
  description = "Path to local submodule directory"
  value       = var.local_git_submodule_path
}

output "git_submodule_current_commit" {
  description = "Current commit SHA from local submodule"
  value       = data.external.git_submodule_head_commit.result.commit
}

output "sync_enabled" {
  description = "Whether synchronization is enabled"
  value       = var.sync_enabled
}
