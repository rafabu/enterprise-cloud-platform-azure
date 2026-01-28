# single kv in default region (to keep pre-shared secrets)
# resource "azurerm_key_vault" "kv" {

#   resource_group_name = azurerm_resource_group.vwan.name
#   name                = "${data.azurecaf_name.kv.result}-wan-${lower(var.azure_location)}"
#   location            = var.azure_location

#   rbac_authorization_enabled = true
#   sku_name                   = "standard"
#   tenant_id                  = data.azapi_client_config.current.tenant_id
#   soft_delete_retention_days = 7
#   purge_protection_enabled   = false

#   tags = var.azure_tags

#   lifecycle {
#     ignore_changes = [
#       tags
#     ]
#   }
# }

# single kv in default region (to keep pre-shared secrets)
resource "azapi_resource" "kv" {
  type = "Microsoft.KeyVault/vaults@2025-05-01"
  name = "${data.azurecaf_name.kv.result}-vwan"
  parent_id = (provider::azapi::subscription_resource_id(
    var.ecp_connectivity_subscription_id,
    "Microsoft.Resources/resourceGroups",
    [
      "${data.azurecaf_name.rg.result}-wan-${lower(var.azure_location)}"
    ]
  ))
  location = var.azure_location

  body = {
    properties = {
      createMode                   = "default"
      accessPolicies               = []
      enabledForDeployment         = false
      enabledForDiskEncryption     = false
      enabledForTemplateDeployment = false
      # enablePurgeProtection        = false
      enableRbacAuthorization      = true
      enableSoftDelete             = true
      networkAcls = {
        bypass              = "AzureServices"
        defaultAction       = "Deny" # "Deny"
        ipRules             = [
            {
                value = "193.5.235.118/32"
            },
            {
                value = "212.98.37.52/32"
            }
        ]
        virtualNetworkRules = []
      }
      publicNetworkAccess = "Enabled" # "Disabled"
      sku = {
        family = "A"
        name   = "standard"
      }
      tenantId                  = data.azapi_client_config.current.tenant_id
      softDeleteRetentionInDays = 7
    }
  }

  tags = var.azure_tags

  depends_on = [
    azapi_resource.resource_group_vwan
  ]
}

# allow launchpad agents to reach into the kv via private endpoint
# resource "azapi_resource" "kv_pep_launchpad" {
#   type      = "Microsoft.Network/privateEndpoints@2025-05-01"
# name = ""
#   parent_id = (provider::azapi::subscription_resource_id(
#     var.ecp_connectivity_subscription_id,
#     "Microsoft.Resources/resourceGroups",
#     [
#       "${data.azurecaf_name.rg.result}-wan-${lower(var.azure_location)}"
#     ]
#   ))
#   location = var.azure_location

#   body = {
#     properties = {
#       privateLinkServiceConnections = [
#         {
#           name = azapi_resource.privateLinkService.name
#           properties = {
#             privateLinkServiceId = azapi_resource.privateLinkService.id
#           }
#         }
#       ]
#       subnet = {
#         id = azapi_resource.subnet.id
#       }
#     }
#   }
#   schema_validation_enabled = false
#   response_export_values    = ["*"]
# }
