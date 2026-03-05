# single kv in default region (to keep pre-shared secrets etc.)
locals {
  key_vault_private_dns_zone_ids = [
    for id in var.private_dns_zone_ids : id
    if endswith(id, "privatelink.vaultcore.azure.net") &&
    # alz without proper config will have placeholder IDs; cannot use those
    strcontains(id, "/subscriptions/00000000-0000-0000-0000-000000000000") == false
  ]
}
resource "azurerm_key_vault" "mgm" {
  provider = azurerm.connectivity

  for_each = toset(try(var.enabled_resources.key_vault, false) ? ["this"] : [])

  resource_group_name = azurerm_resource_group.mgm.name
  name = join("-", compact([
    data.azurecaf_name.kv.result,
    local.location_code[lower(local.hub_locations["main"].azure_location)]
  ]))
  location = local.hub_locations["main"].azure_location

  sku_name  = "standard"
  tenant_id = data.azurerm_client_config.con.tenant_id

  access_policy                   = []
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
  rbac_authorization_enabled      = true

  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  public_network_access_enabled = true
  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }

  tags = var.azure_tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}


resource "azurerm_private_endpoint" "mgm_vault" {
  provider = azurerm.connectivity

  for_each = toset(try(var.enabled_resources.key_vault, false) ? ["this"] : [])

  location            = azurerm_key_vault.mgm[each.key].location
  name                = "${azurerm_key_vault.mgm[each.key].name}-pep"
  resource_group_name = azurerm_key_vault.mgm[each.key].resource_group_name
  subnet_id = provider::azapi::resource_group_resource_id(
    var.ecp_connectivity_subscription_id, azurerm_resource_group.mgm.name,
    "Microsoft.Network/virtualNetworks/subnets",
    [
      azurerm_virtual_network.mgm["main_${var.ecp_archetype_definitions.virtual_network}"].name,
      "default"
    ]
  )
  custom_network_interface_name = "${azurerm_key_vault.mgm[each.key].name}-pepnic"

  private_service_connection {
    is_manual_connection           = false
    name                           = "pse-${azurerm_key_vault.mgm[each.key].name}-pep"
    private_connection_resource_id = azurerm_key_vault.mgm[each.key].id
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
