# Process all template files in lib-artefacts subdirectories
#     and drop the rendered files into local temp folder
#     to be consumed by alz provider later
locals {
  alz_library_folder_exists = provider::local::direxists("${var.alz_library_path_shared}")
  alz_library_template_files = local.alz_library_folder_exists ? {
    for path in fileset(
      "${var.alz_library_path_shared}", "**/${var.alz_library_terraform_template_file_name.match_pattern}"
      ) : path => {
      template_file_path    = path
      destination_file_path = "${trimsuffix(var.alz_library_path_shared_rendered, "/")}/${replace(path, var.alz_library_terraform_template_file_name.name_remove_string, "")}"
      rendered_file_content = templatefile(
        "${var.alz_library_path_shared}/${path}", {
          ecp_environment_name = var.ecp_environment_name
        }
      )
    }
  } : {}
}

output "zzz_alz_library_path_shared" {
  value = var.alz_library_path_shared
}
output "zzz_alz_library_folder_exists" {
  value = local.alz_library_folder_exists
}

output "zzz_alz_library_path_shared_rendered" {
  description = "Debug output - list of ALZ library template files processed"
  value       = var.alz_library_path_shared_rendered
}

output "zzz_alz_library_path_shared_rendered_exists" {
  value = provider::local::direxists(var.alz_library_path_shared_rendered)
}

output "zzz_alz_library_path_shared_rendered_fileset" {
  description = "Debug output - list of ALZ library template files processed"
  value       = fileset("${var.alz_library_path_shared_rendered}", "**/*")
}

output "zzz_alz_library_template_files" {
  description = "Debug output - list of ALZ library template files processed"
  value       = local.alz_library_template_files
}

data "external" "alz_library_artefact_templating" {
  for_each = toset(local.alz_library_folder_exists ? [var.alz_library_path_shared] : [])

  program = ["pwsh", "-NoLogo", "-NonInteractive", "-ExecutionPolicy", "RemoteSigned", "-File", "${path.module}/Write-RenderedArtefacts.ps1"]

  query = {
    # arbitrary map from strings to strings, passed
    # to the external program as the data query.
    rendered_files_base64 = textencodebase64(
      jsonencode(
        local.alz_library_template_files
      ), "UTF-16LE"
    ) # UTF-16LE --> PowerShell compatible
  }
}

resource "terraform_data" "alz_library_artefact_templating" {
  for_each = toset(local.alz_library_folder_exists ? [var.alz_library_path_shared] : [])

  input = {
    files_written = data.external.alz_library_artefact_templating[each.key].result.files_written
    status        = data.external.alz_library_artefact_templating[each.key].result.status
    folder_exists = provider::local::direxists(var.alz_library_path_shared_rendered)
    files         = jsonencode(fileset("${var.alz_library_path_shared_rendered}", "**/*"))
  }

  depends_on = [
    data.external.alz_library_artefact_templating
  ]
}

output "zzz_alz_library_artefact_templating" {
  description = "Debug output - ALZ library artefact templating results"
  value       = terraform_data.alz_library_artefact_templating
}
