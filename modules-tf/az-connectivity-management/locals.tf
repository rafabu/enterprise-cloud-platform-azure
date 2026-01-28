locals {

  # ECP ARTEFACT DEFAULTS
  parsed_network_artefacts = {
    for k, v in var.virtual_network_artefacts : k => jsondecode(file(v.filePath))
    # we need all here, as the wan hub artefact contains the filter statement
  }
  parsed_network_subnet_artefacts = {
    for k, v in var.virtual_network_subnet_artefacts : k => jsondecode(file(v.filePath))
    # we need all here, as the wan hub artefact contains the filter statement
  }
  

  
}

output "zzz_parsed_network_artefacts" {
  value = local.parsed_network_artefacts
}

output "zzz_parsed_network_subnet_artefacts" {
  value = local.parsed_network_subnet_artefacts
} 
