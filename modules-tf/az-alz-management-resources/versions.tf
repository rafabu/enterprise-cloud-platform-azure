terraform {
  required_version = ">= 1.15"
  required_providers {
    alz = {
      source  = "azure/alz"
      version = "~> 0.20"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.7"
    }
     external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.6"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}
