# THIS FILE SHOULD NORMALLY BE REPLACED DURING TERRAGRUNT UNIT INITIALIZATION. IT IS ONLY PRESENT AS A PLACEHOLDER
provider "azurecaf" {}

provider "azurerm" {
  alias = "launchpad"

  environment         = "public"
  storage_use_azuread = true

  # core are: 
  # - Microsoft.Authorization
  # - Microsoft.Compute
  # - Microsoft.CostManagement
  # - Microsoft.ManagedIdentity
  # - Microsoft.MarketplaceOrdering
  # - Microsoft.Network
  # - Microsoft.Resources
  # - Microsoft.Storage
  resource_provider_registrations = "core"
  # add all required providers for the launchpad subscription to hosts its resources
  resource_providers_to_register = [
    "Microsoft.DevCenter",
    "Microsoft.DevOpsInfrastructure",
    "Microsoft.Quota"
  ]

  features {
  }

  provider "azapi" {

    skip_provider_registration = true
  }
}
