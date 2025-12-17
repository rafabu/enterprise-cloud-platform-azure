output "alz_library_artefact_templating_result" {
  value = toset(local.alz_library_folder_exists ? [var.alz_library_path_shared] : []) ? data.external.alz_library_artefact_templating.result : {}
}
