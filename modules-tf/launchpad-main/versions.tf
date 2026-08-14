# THIS FILE SHOULD NORMALLY BE REPLACED DURING TERRAGRUNT UNIT INITIALIZATION. IT IS ONLY PRESENT AS A PLACEHOLDER
terraform {
  required_version = ">= 1.15"
  required_providers {
     azapi = {
      source = "azure/azapi"
      version = "~> 2.12"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~> 1.2"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
  }
}
