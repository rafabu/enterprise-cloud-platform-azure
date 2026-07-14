data "azurecaf_name" "rg" {
  name          = try(var.azure_resource_name_elements.name, null)
  resource_type = "azurerm_resource_group"
  prefixes      = try(var.azure_resource_name_elements.prefixes, [])
  suffixes      = try(var.azure_resource_name_elements.suffixes, [])
  random_length = try(var.azure_resource_name_elements.random_length, 0)
  clean_input   = true
  use_slug      = true
}

data "azurecaf_name" "vnet" {
  name          = try(var.azure_resource_name_elements.name, null)
  resource_type = "azurerm_virtual_network"
  prefixes      = try(var.azure_resource_name_elements.prefixes, [])
  suffixes      = try(var.azure_resource_name_elements.suffixes, [])
  random_length = try(var.azure_resource_name_elements.random_length, 0)
  clean_input   = true
  use_slug      = true
}

data "azurecaf_name" "bas" {
  name          = try(var.azure_resource_name_elements.name, null)
  resource_type = "azurerm_bastion_host"
  prefixes      = try(var.azure_resource_name_elements.prefixes, [])
  suffixes      = try(var.azure_resource_name_elements.suffixes, [])
  random_length = try(var.azure_resource_name_elements.random_length, 0)
  clean_input   = true
  use_slug      = true
}

output "bastion_name" {
  value       = data.azurecaf_name.bas.result
  description = "The name of the bastion host."
}