locals {
  # Generate unique trigger based on commits and force sync flag
  sync_trigger = var.sync_enabled ? (
    var.force_sync ? 
    "${local.submodule_current_commit}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" :
    "${data.azuredevops_git_repository.target.default_branch}-${local.submodule_current_commit}"
  ) : "disabled"
  
    # Local submodule commit hash for change detection
  # submodule_commit_hash = try(file("${var.local_submodule_path}/.git/refs/heads/main"), "unknown")
}