output "alz_library" {
  value = var.ecp_deployment_alz_library
}

output "alz_library_path_shared" {
  value = local.alz_library_path_shared
}

output "alz_library_path_shared_rendered" {
  value = var.alz_library_path_shared_rendered
}

output "alz_library_artefact_templating_result" {
  value = local.alz_library_folder_exists ? data.external.alz_library_artefact_templating[local.alz_library_path_shared].result : {
    files_written     = "0"
    status = "ERROR: ALZ library folder does not exist at '${local.alz_library_path_shared}'"
  }
}
