# single kv in default region (to keep pre-shared secrets etc.)
locals {
  key_vault_private_dns_zone_ids = [
    for id in var.private_dns_zone_ids : id
    if endswith(id, "privatelink.vaultcore.azure.net") &&
    # alz without proper config will have placeholder IDs; cannot use those
    strcontains(id, "/subscriptions/00000000-0000-0000-0000-000000000000") == false
  ]
}

# azurerm_key_vault queries data plane; switch to azapi so this can proceed even with
#     firewall closed and no public endpoint
#     Note: No secret resource created in this step - hence no data plane access needed at this point
resource "azapi_resource" "mgm_vault" {
  for_each = toset(try(var.enabled_resources.key_vault, false) ? ["this"] : [])

  type      = "Microsoft.KeyVault/vaults@2026-02-01"
  name      = join("-", compact([
    data.azurecaf_name.kv.result,
    local.location_code[lower(local.hub_locations["main"].azure_location)]
  ]))
  location  = local.hub_locations["main"].azure_location
  parent_id = azurerm_resource_group.mgm.id

  body = {
    properties = {
      sku                            = { family = "A", name = "standard" }
      tenantId                       = data.azurerm_client_config.con.tenant_id
      accessPolicies                 = []
      enabledForDeployment           = false
      enabledForDiskEncryption       = false
      enabledForTemplateDeployment   = false
      enableRbacAuthorization        = true
      enableSoftDelete               = true
      softDeleteRetentionInDays      = 7
      enablePurgeProtection          = null   # omit = disabled
      publicNetworkAccess            = "Enabled"
      networkAcls = {
        bypass        = "AzureServices"
        defaultAction = "Deny"
        ipRules       = []
        virtualNetworkRules = []
      }
    }
  }

  tags = var.azure_tags

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_private_endpoint" "mgm_vault" {
  provider = azurerm.connectivity

  for_each = toset(try(var.enabled_resources.key_vault, false) ? ["this"] : [])

  location            = azapi_resource.mgm_vault[each.key].location
  name                = "${azapi_resource.mgm_vault[each.key].name}-pep"
  resource_group_name = azurerm_resource_group.mgm.name
  subnet_id           = values(azurerm_subnet.mgm)[0].id
  custom_network_interface_name = "${azapi_resource.mgm_vault[each.key].name}-pepnic"

  private_service_connection {
    is_manual_connection           = false
    name                           = "pse-${azapi_resource.mgm_vault[each.key].name}-pep"
    private_connection_resource_id = azapi_resource.mgm_vault[each.key].id
    subresource_names              = ["vault"]
  }

  # if DNS zone is missing, it would be created by Azure policy 'Deploy-Private-DNS-Zones'
  #     if adding here, it will be operational much quicker than waiting for policy to kick in
  dynamic "private_dns_zone_group" {
    for_each = length(local.key_vault_private_dns_zone_ids) > 0 ? [1] : []
    content {
      name                 = "ecpPrivateDnsZoneGroup"
      private_dns_zone_ids = local.key_vault_private_dns_zone_ids
    }
  }

  tags = var.azure_tags

  lifecycle {
    ignore_changes = [
      private_dns_zone_group, # ignore changes to private DNS zone groups, as it is managed by Azure policy
      tags
    ]
  }
}
