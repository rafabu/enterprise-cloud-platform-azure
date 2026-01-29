resource "azurerm_resource_group" "mgm" {
  provider = azurerm.connectivity


  name     = "${data.azurecaf_name.rg.result}-mgmt"
  location = var.azure_location

  tags = var.azure_tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
