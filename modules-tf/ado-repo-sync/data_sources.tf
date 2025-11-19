# Data source for Azure DevOps repository to get current commit info
data "azuredevops_git_repository" "target" {
  project_id = data.azuredevops_project.this.id
  name       = var.ecp_azure_devops_repository_name
}

# Data source for Azure DevOps project
data "azuredevops_project" "this" {
  name = var.ecp_azure_devops_project_name
}

# Local data source for submodule commit detection
data "local_file" "submodule_head" {
  count = var.sync_enabled && try(fileexists("${var.local_submodule_path}/.git/HEAD"), false) ? 1 : 0
  
  filename = "${var.local_submodule_path}/.git/HEAD"
}

output "submodule_head_content_file" {
  description = "Content of the submodule HEAD file for debugging"
  value       = data.local_file.submodule_head[0].content
  sensitive   = false
}

# Fallback: read current branch ref if HEAD points to a branch
data "local_file" "submodule_current_branch_ref" {
  count = var.sync_enabled && can(regex("ref: refs/heads/", try(data.local_file.submodule_head[0].content, ""))) ? 1 : 0
  
  filename = "${var.local_submodule_path}/.git/${trimspace(replace(try(data.local_file.submodule_head[0].content, ""), "ref: ", ""))}"
}

output "submodule_head_content_file_ref" {
  description = "Content of the submodule current branch ref file for debugging"
  value       = data.local_file.submodule_current_branch_ref[0].content
  sensitive   = false
}

# Alternative: direct commit hash if HEAD contains a commit hash
locals {
  # Extract current commit hash from submodule
  submodule_current_commit = var.sync_enabled ? (
    can(regex("^[0-9a-f]{40}$", trimspace(try(data.local_file.submodule_head[0].content, "")))) ?
    trimspace(data.local_file.submodule_head[0].content) :
    trimspace(try(data.local_file.submodule_current_branch_ref[0].content, "unknown"))
  ) : "disabled"
  
  # Generate a hash of directory contents as fallback for change detection
  submodule_content_hash = var.sync_enabled ? md5(join("", [
    for f in fileset(var.local_submodule_path, "**/*") :
    fileexists("${var.local_submodule_path}/${f}") && !can(regex("\\.git/", f)) ?
    md5(file("${var.local_submodule_path}/${f}")) : ""
  ])) : "disabled"
}