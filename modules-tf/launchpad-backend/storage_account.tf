resource "azurerm_storage_account" "backend" {
  provider = azurerm.launchpad

  for_each = toset(local.backend_levels)

  name                = format("%s-%s", data.azurecaf_name.st.result, each.key)
  resource_group_name = azurerm_resource_group.backend.name

  location                 = azurerm_resource_group.backend.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  shared_access_key_enabled = false
  public_network_access_enabled = false
  default_to_oauth_authentication = true
  local_user_enabled = false
  allow_blob_public_access = false

  infrastructure_encryption_enabled = true
  queue_encryption_key_type = "Account"
  table_encryption_key_type = "Account"

  sftp_enabled = false

  dns_endpoint_type = "Standard"

  # network_rules {
  #   default_action             = "Deny"
  #   ip_rules                   = ["100.0.0.1"]
  #   virtual_network_subnet_ids = [azurerm_subnet.example.id]
  # }

  tags = var.azure_tags
}
