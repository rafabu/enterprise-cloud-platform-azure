resource "azurerm_resource_provider_registration" "microsoft_devopsinfrastructure" {
  provider = azurerm.lauchpad

  name = "Microsoft.DevOpsInfrastructure"
}

resource "azurerm_resource_provider_registration" "microsoft_devcenter" {
  provider = azurerm.lauchpad

  name = "Microsoft.DevCenter"
}
