data "azurecaf_name" "pipeline" {
  for_each = toset(var.ado_yaml_pipeline_artefact_names)

  name          = try(var.azure_resource_name_elements.name, null)
  resource_type = "azurerm_virtual_network"
  prefixes      = try(var.azure_resource_name_elements.prefixes, [])
  suffixes      = try(var.azure_resource_name_elements.suffixes, [])
  random_length = try(var.azure_resource_name_elements.random_length, 0)
  clean_input   = true
  use_slug      = true
}


output "zzz_names" {
  description = "Names generated for Azure DevOps pipelines"
  value       = data.azurecaf_name.pipeline
}
