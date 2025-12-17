variable "ecp_environment_name" {
  type        = string
  description = "Name of the ECP environment (used for naming resources)"
}

variable "alz_library_path_shared" {
  type        = string
  description = "Path to the shared ALZ library artefacts."
}

variable "alz_library_path_shared_rendered" {
  type        = string
  description = "Path to the rendered shared ALZ library artefacts."
  default     = "./not-set"
}

variable "alz_library_terraform_template_file_name" {
  type = object({
    match_pattern      = string
    name_remove_string = string
  })
  default = {
    match_pattern      = "**.tftemplate.json"
    name_remove_string = ".tftemplate"
  }
  description = "Pattern to match Terraform template files in the unit's ALZ library artefacts."
}
