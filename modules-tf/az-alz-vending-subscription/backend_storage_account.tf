# use storage account AVM to avoind issues with azurerm provider
module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = var.avm-res-storage-storageaccount_version

  for_each = toset(var.storage_account_creation_enabled ? ["this"] : [])

  name      = data.azurecaf_name.st.result
  location  = azapi_resource.resource_group_management.location
  parent_id = azapi_resource.resource_group_management.id

  account_kind                    = "StorageV2"
  account_sku_name                = "Standard_ZRS"
  default_to_oauth_authentication = true
  shared_access_key_enabled       = false

  is_hns_enabled           = false
  large_file_share_enabled = false
  nfsv3_enabled            = false

  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"

  infrastructure_encryption_enabled = true
  queue_encryption_key_type         = "Account"
  table_encryption_key_type         = "Account"

  allow_nested_items_to_be_public = false
  # public network access: is disabled by policy in corp
  public_network_access_enabled = var.resource_network_communication_mode == "PrivateLink" ? false : true

  blob_properties = {
    change_feed_enabled      = false
    last_access_time_enabled = true
    versioning_enabled       = true
    delete_retention_policy = {
      # keep tfstates for 91 days after deletion
      days = 91
    }
  }

  managed_identities = {
    system_assigned = true
  }

  network_rules = merge(
    {
      bypass                     = ["AzureServices"]
      default_action             = "Deny"
      ip_rules                   = []
      virtual_network_subnet_ids = var.resource_network_communication_mode == "ServiceEndpoint" ? local.subnet_resource_ids : null
    },
    var.storage_account_network_rules
  )

  private_endpoints_manage_dns_zone_group = true
  private_endpoints = var.resource_network_communication_mode == "PrivateLink" ? {
    blob = {
      name                   = "${data.azurecaf_name.st.result}-pep-blob"
      network_interface_name = "${data.azurecaf_name.st.result}-pep-blob-nic"

      subresource_name   = "blob"
      subnet_resource_id = var.resource_network_communication_mode == "PrivateLink" ? local.private_endpoint_subnet_resource_ids[0] : null
      private_dns_zone_resource_ids = distinct([
        for id in var.private_dns_zone_resource_ids : id
        if endswith(id, "privatelink.blob.core.windows.net")
      ])
    }
  } : null

  containers = {
    blob_container_tfstate = {
      name = "tfstate"
    },

  }

  tags = azapi_resource.resource_group_management.tags

  enable_telemetry = false
}

# # DoNotDelete locks on resources
resource "azapi_resource" "storage_account_container_lock" {
  for_each = toset(var.storage_account_creation_enabled ? ["this"] : [])

  type = "Microsoft.Authorization/locks@2020-05-01"

  name      = "${module.storage_account["this"].name}-container-tfstate-lock-cannotdelete"
  parent_id = "${module.storage_account["this"].resource_id}/blobServices/default/containers/tfstate"

  body = {
    properties = {
      level = "CanNotDelete"
      notes = "Prevents accidental deletion of the storage account's \"tfstate\" container"
    }
  }
}

resource "azapi_resource" "storage_account_private_endpoint_blob_lock" {
  for_each = toset(var.storage_account_creation_enabled == true && var.resource_network_communication_mode == "PrivateLink" ? ["this"] : [])

  type = "Microsoft.Authorization/locks@2020-05-01"

  name      = "${data.azurecaf_name.st.result}-pep-blob-lock-cannotdelete"
  parent_id = "${azapi_resource.resource_group_management.id}/providers/Microsoft.Network/privateEndpoints/${data.azurecaf_name.st.result}-pep-blob"

  body = {
    properties = {
      level = "CanNotDelete"
      notes = "Prevents accidental deletion of the storage account's blob private endpoint"
    }
  }

  depends_on = [
    module.storage_account
  ]
}
