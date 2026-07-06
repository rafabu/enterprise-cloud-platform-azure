# # use storage account AVM to avoind issues with azurerm provider
# module "storage_account" {
#   source  = "Azure/avm-res-storage-storageaccount/azurerm"
#   version = var.avm_res_storage_storageaccount_version

#   for_each = toset(var.create_storage_account ? ["this"] : [])

#   location  = var.default_region
#   name      = local.storage_account_name
#   parent_id = module.resource_group_management.resource_id

#   # account_replication_type        = "ZRS"
#   # account_tier                    = "Standard"
#   account_kind                    = "StorageV2"
#   account_sku_name                = "Standard_ZRS"
#   default_to_oauth_authentication = true
#   shared_access_key_enabled       = false

#   is_hns_enabled           = false
#   large_file_share_enabled = false
#   nfsv3_enabled            = false

#   https_traffic_only_enabled = true
#   min_tls_version            = "TLS1_2"

#   infrastructure_encryption_enabled = true
#   queue_encryption_key_type         = "Account"
#   table_encryption_key_type         = "Account"

#   allow_nested_items_to_be_public = false
#   # public network access: is disabled by policy in corp
#   public_network_access_enabled = var.resource_network_communication_mode == "PrivateLink" ? false : true

#   blob_properties = {
#     change_feed_enabled      = false
#     last_access_time_enabled = true
#     versioning_enabled       = true
#     delete_retention_policy = {
#       # keep tfstates for 91 days after deletion
#       days = 91
#     }
#   }

#   managed_identities = {
#     system_assigned = true
#   }

#   network_rules = merge(
#     {
#       bypass         = ["AzureServices"]
#       default_action = "Deny"
#       ip_rules       = []
#       virtual_network_subnet_ids = var.resource_network_communication_mode == "ServiceEndpoint" ? [
#         for key, val in module.vnet.subnets : val.resource_id
#       ] : null
#     },
#     var.storage_account_network_rules
#   )

#   containers = {
#     blob_container_tfstate = {
#       name = "tfstate"
#     },

#   }

#   tags = var.azure_tags

#   enable_telemetry = false
# }


# # need to ignore DNS zone changes (managed by policy) - cannot use AVM due to this
# resource "azurerm_private_endpoint" "storage_account" {
#   for_each = toset([
#     for key, val in var.workload_subnet_configuration : key
#     if val.private_endpoint_allocate == true &&
#     var.create_storage_account == true &&
#     var.resource_network_communication_mode == "PrivateLink"
#   ])

#   provider = azurerm.azurerm_workload

#   location            = var.default_region
#   name                = "${local.storage_account_name}-pep-${each.key}"
#   resource_group_name = module.resource_group_management.name

#   subnet_id                     = module.vnet.subnets[each.key].resource_id
#   custom_network_interface_name = "${local.storage_account_name}-pepnic-blob-${each.key}"

#   private_service_connection {
#     is_manual_connection           = false
#     name                           = "pse-${local.storage_account_name}-pep-${each.key}"
#     private_connection_resource_id = module.storage_account.this.resource_id
#     subresource_names              = ["blob"]
#   }

#   tags = var.azure_tags

#   lifecycle {
#     ignore_changes = [
#       private_dns_zone_group, # ignore changes to private DNS zone groups, as it is managed by Azure policy
#       tags
#     ]
#   }
# }

# # DoNotDelete locks on resources
# resource "azurerm_management_lock" "storage_account_container_tfstate" {
#   for_each = toset(var.create_storage_account ? ["this"] : [])

#   provider = azurerm.azurerm_workload

#   name       = "${module.storage_account["this"].name}-container-tfstate-lock-cannotdelete"
#   scope      = "${module.storage_account["this"].resource_id}/blobServices/default/containers/tfstate"
#   lock_level = "CanNotDelete"
#   notes      = "Prevents accidental deletion of the storage account's \"tfstate\" container"
# }

# resource "azurerm_management_lock" "storage_account_private_endpoint" {
#   for_each = toset([
#     for key, val in var.workload_subnet_configuration : key
#     if val.private_endpoint_allocate == true &&
#     var.create_storage_account == true &&
#     var.resource_network_communication_mode == "PrivateLink"
#   ])

#   provider = azurerm.azurerm_workload

#   name       = "${azurerm_private_endpoint.storage_account["this"].name}-lock-cannotdelete"
#   scope      = azurerm_private_endpoint.storage_account[each.key].id
#   lock_level = "CanNotDelete"
#   notes      = "Prevents accidental deletion of the storage account private endpoint"
# }
