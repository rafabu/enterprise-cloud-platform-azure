locals {
  name_prefixes = join("-", try(var.azure_resource_name_elements.prefixes, []))

  name_template_role_assignable    = "ra-${local.name_prefixes}-${var.azure_resource_name_elements.name}-<role>"
  name_template_role_managed       = "rm-${local.name_prefixes}-${var.azure_resource_name_elements.name}-<role>"
  name_template_permission_managed = "pm-${local.name_prefixes}-${var.azure_resource_name_elements.name}-<permission>"

  devops_variable_group_name     = "automation-vargrp-default"

}
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

data "azurecaf_name" "vnet" {
  name          = try(var.azure_resource_name_elements.name, null)
  resource_type = "azurerm_virtual_network"
  prefixes      = try(var.azure_resource_name_elements.prefixes, [])
  suffixes      = try(var.azure_resource_name_elements.suffixes, [])
  random_length = try(var.azure_resource_name_elements.random_length, 0)
  clean_input   = true
  use_slug      = true
}

data "azurecaf_name" "nsg" {
  name          = try(var.azure_resource_name_elements.name, null)
  resource_type = "azurerm_network_security_group"
  prefixes      = try(var.azure_resource_name_elements.prefixes, [])
  suffixes      = try(var.azure_resource_name_elements.suffixes, [])
  random_length = try(var.azure_resource_name_elements.random_length, 0)
  clean_input   = true
  use_slug      = true
}



locals {
  variable_group_name = format(
    "ecp_bootstrap_%s",
    join("-", try(var.azure_resource_name_elements.prefixes, []))
  )
}
