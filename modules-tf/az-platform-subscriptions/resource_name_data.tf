data "azurecaf_name" "rg" {
  name          = try(var.azure_resource_name_elements.name, null)
  # azurerm_subscription is not implemented - use azurerm_resource_group for resource_type
  resource_type = "azurerm_resource_group"
  prefixes      = try(var.azure_resource_name_elements.prefixes, [])
  suffixes      = null # try(var.azure_resource_name_elements.suffixes, [])
  random_length = try(var.azure_resource_name_elements.random_length, 0)
  clean_input   = true
  use_slug      = true
}
