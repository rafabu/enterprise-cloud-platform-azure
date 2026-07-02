terraform {
  required_version = ">= 1.15"
  required_providers {
    alz = {
      source  = "azure/alz"
      version = "~> 0.20"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.5"
    }
    modtm = {
      source  = "Azure/modtm"
      version = "~> 0.3"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~> 1.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
