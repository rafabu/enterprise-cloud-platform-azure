data "azurerm_client_config" "con" {
  provider = azurerm.connectivity
}

# where resource names include location info, use short names
module "azure-region-info" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.12.0"

  enable_telemetry = false
}
