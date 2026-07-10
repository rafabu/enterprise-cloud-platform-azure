terraform {
  required_version = "~> 1.10"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.5"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.9"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~>1.15"
    }
  }
}
