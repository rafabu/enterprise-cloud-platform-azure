terraform {
  required_version = ">= 1.15"
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.10"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.9"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1.15"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.75"
    }
  }
}
