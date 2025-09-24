data "azurecaf_name" "rg" {
  name          = try(var.azure_resource_name_elements.name, null)
  resource_type = "azurerm_resource_group"
  prefixes      = try(var.azure_resource_name_elements.prefixes, [])
  suffixes      = try(var.azure_resource_name_elements.suffixes, [])
  random_length = try(var.azure_resource_name_elements.random_length, 0)
  clean_input   = true
  use_slug      = true
}

data "azurecaf_name" "st" {
  name          = try(var.azure_resource_name_elements.name, null)
  resource_type = "azurerm_storage_account"
  prefixes      = try(var.azure_resource_name_elements.prefixes, [])
  suffixes      = try(var.azure_resource_name_elements.suffixes, [])
  random_length = try(var.azure_resource_name_elements.random_length, 0)
  clean_input   = true
  use_slug      = true
}

locals {
  # used to match service principal names against the naming convention used by ECP Launchpad
  service_principal_name_begins_with = format(
    "ar-%s-%s",
    join("-", try(var.azure_resource_name_elements.prefixes, [])),
    try(var.azure_resource_name_elements.name, null)
  )

  managed_identity_name_begins_with = format(
    "%s-id-%s",
    join("-", try(var.azure_resource_name_elements.prefixes, [])),
    try(var.azure_resource_name_elements.name, null),
  )
}
