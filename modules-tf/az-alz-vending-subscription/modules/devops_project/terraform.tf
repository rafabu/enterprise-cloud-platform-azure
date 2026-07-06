terraform {
  required_version = "~> 1.10"

  required_providers {
    azuredevops = {
      source = "microsoft/azuredevops"
      version = "~>1.15"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}