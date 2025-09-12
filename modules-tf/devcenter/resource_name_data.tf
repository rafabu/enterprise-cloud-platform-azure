data "azurecaf_name" "rg" {
  name          = try(var.azure_resource_name_elements.name, null)
  resource_type = "azurerm_resource_group"
  prefixes      = try(var.azure_resource_name_elements.prefixes, [])
  suffixes      = try(var.azure_resource_name_elements.suffixes, [])
  random_length = try(var.azure_resource_name_elements.random_length, 0)
  clean_input   = true
  use_slug      = true
}
