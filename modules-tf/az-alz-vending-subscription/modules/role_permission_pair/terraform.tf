terraform {
  required_version = "~> 1.10"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.9" # 3.9 contains specific fixes for PIM
    }
  }
}