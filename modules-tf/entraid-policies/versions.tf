terraform {
  required_version = ">= 1.12"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.5"
    }
    msgraph = {
      source  = "Microsoft/msgraph"
      version = "~> 0.1"
    }
  }
}
