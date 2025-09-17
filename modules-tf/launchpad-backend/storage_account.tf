resource "azurerm_storage_account" "backend" {
  provider = azurerm.launchpad

  for_each = toset(local.backend_levels)

  name                = format("%s%s", data.azurecaf_name.st.result, each.key)
  resource_group_name = azurerm_resource_group.backend.name
  location            = azurerm_resource_group.backend.location

  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "LRS"
  access_tier              = "Hot"

  allow_nested_items_to_be_public = false
  default_to_oauth_authentication = true
  local_user_enabled              = false
  public_network_access_enabled   = false
  # you will need to enable the storage_use_azuread flag in the Provider block to use Azure AD for authentication
  shared_access_key_enabled = false

  is_hns_enabled           = false
  large_file_share_enabled = false
  nfsv3_enabled            = false

  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"

  infrastructure_encryption_enabled = true
  queue_encryption_key_type         = "Account"
  table_encryption_key_type         = "Account"

  cross_tenant_replication_enabled = false

  sftp_enabled = false

  dns_endpoint_type = "Standard"

  blob_properties {
    versioning_enabled       = true
    last_access_time_enabled = true
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.azure_tags
}

resource "azurerm_private_endpoint" "backend_blob" {
  provider = azurerm.launchpad

  for_each = toset(local.backend_levels)

  location            = azurerm_resource_group.backend.location
  name                = "${azurerm_storage_account.backend[each.key].name}-pep-blob"
  resource_group_name = azurerm_storage_account.backend[each.key].resource_group_name

  subnet_id                     = var.virtual_subnet_id
  custom_network_interface_name = "${azurerm_storage_account.backend[each.key].name}-pepnic-blob"

  private_service_connection {
    is_manual_connection           = false
    name                           = "pse-${azurerm_storage_account.backend[each.key].name}-pep-blob"
    private_connection_resource_id = azurerm_storage_account.backend[each.key].id
    subresource_names              = ["blob"]
  }

  tags = var.azure_tags

  lifecycle {
    ignore_changes = [
      private_dns_zone_group # ignore changes to private DNS zone groups, as it is managed by Azure policy
    ]
  }
}


# This uses azapi in order to avoid having to wait for data plane permissions and deal with propagation delay
resource "azapi_resource" "tfstate_container" {
  for_each = toset(local.backend_levels)

  name      = "tfstate"
  parent_id = "${azurerm_storage_account.backend[each.key].id}/blobServices/default"
  type      = "Microsoft.Storage/storageAccounts/blobServices/containers@2025-01-01"
  body = {
    properties = {
      metadata                       = {}
      publicAccess                   = "None"
      immutableStorageWithVersioning = {}
    }
  }
}
