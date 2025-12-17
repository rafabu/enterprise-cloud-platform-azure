output "alz_library_artefact_templating_result" {
  value = local.alz_library_folder_exists ? data.external.alz_library_artefact_templating[var.alz_library_path_shared].result : {}
}
