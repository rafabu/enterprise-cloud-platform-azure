# where resource names include location info, use short names
module "azure-region-info" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = var.avm-utl-regions_version

  enable_telemetry = false
}
