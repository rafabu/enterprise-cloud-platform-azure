terraform {
  required_version = "~> 1.10"

  required_providers {
    azuread = {
      source  = "Azure/azuread"
      version = "~> 3.9" # 3.9 contains specific fixes for PIM
    }
  }
}