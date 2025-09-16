resource "azurerm_storage_account" "backend" {
  provider = azurerm.launchpad

  for_each = toset(local.backend_levels)

  name                = format("%s-%s", data.azurecaf_name.st.result, each.key)
  resource_group_name = azurerm_resource_group.backend.name
  location            = azurerm_resource_group.backend.location

  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "LRS"

  allow_nested_items_to_be_public = false
  default_to_oauth_authentication = true
  local_user_enabled              = false
  public_network_access_enabled   = false
  shared_access_key_enabled       = false

  is_hns_enabled           = false
  large_file_share_enabled = false
  nfsv3_enabled            = false

  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"

  infrastructure_encryption_enabled = true
  queue_encryption_key_type         = "Account"
  table_encryption_key_type         = "Account"

  sftp_enabled = false

  dns_endpoint_type = "Standard"

  blob_properties = {
    versioning_enabled       = true
    last_access_time_enabled = true
  }

  managed_identities = {
    system_assigned = true
  }

  containers = {
    blob_container_tfstate = {
      name = "tfstate"
    }
  }

  tags = var.azure_tags
}
