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
  value       = var.local_submodule_path
}

output "sync_trigger" {
  description = "Current sync trigger value (changes when sync is needed)"
  value       = local.sync_trigger
}

output "submodule_current_commit" {
  description = "Current commit SHA from local submodule"
  value       = local.submodule_current_commit
}

output "submodule_content_hash" {
  description = "Content hash of submodule files (fallback change detection)"
  value       = local.submodule_content_hash
  sensitive   = false
}

output "sync_enabled" {
  description = "Whether synchronization is enabled"
  value       = var.sync_enabled
}