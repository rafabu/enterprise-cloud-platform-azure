locals {
  # connectivity (Private DNS Zones)
  subscription_id_connectivity = var.ecp_connectivity_subscription_id != "00000000-0000-0000-0000-000000000000" ? var.ecp_connectivity_subscription_id : var.ecp_management_subscription_id
}

resource "azapi_resource" "resource_group" {
  type      = "Microsoft.Resources/resourceGroups@2025-04-01"
  name      = "${data.azurecaf_name.rg.result}-privatelink-dnszones"
  parent_id = "/subscriptions/${local.subscription_id_connectivity}"
  location  = var.azure_location

  tags = var.azure_tags
}


locals {
  additional_private_dns_zones = {
    # additional zones to be deployed to avm-ptn-network-private-link-private-dns-zones module's default parameter 'private_link_private_dns_zones'.
    #  but was amended to work with the ALZ policy initiative 'Deploy-Private-DNS-Zones'.
    #  last checked with:
    #     - avm-ptn-network-private-link-private-dns-zones version 0.23.2
    #     - Deploy-Private-DNS-Zones version 2.5.0
    #      https://github.com/Azure/terraform-azurerm-avm-ptn-network-private-link-private-dns-zones
    #      https://github.com/Azure/Azure-Landing-Zones-Library/blob/main/platform/alz/policy_set_definitions/Deploy-Private-DNS-Zones.alz_policy_set_definition.json

    # in ALZ 2026.04.2 (policy initiative Deploy-Private-DNS-Zones v2.5.0) but not in #     AVM avm-ptn-network-private-link-private-dns-zones 0.23.2 (11.06.2026):
    azure_acr_data_default_location = {
      zone_name = "${lower(var.azure_location)}.data.privatelink.azurecr.io"
    }
  }

  # missing from
  #     ALZ 2026.04.2 (policy initiative Deploy-Private-DNS-Zones v2.5.0)
  # but present in 
  #     AVM avm-ptn-network-private-link-private-dns-zones 0.23.2 (11.06.2026):
  # - privatelink.openai.azure.com:             azure_ai_oai
  # - privatelink.mysql.database.azure.com:     azure_mysql_db_server
  # - privatelink.postgres.database.azure.com:  azure_postgres_sql_server
  # - privatelink.purview.azure.com:            azure_purview_account
  # - privatelink.purviewstudio.azure.com:      azure_purview_studio
  # - privatelink.azurestaticapps.net:          azure_static_web_apps
  # - privatelink.1.azurestaticapps.net:        azure_static_web_apps_partitioned_1
  # - privatelink.2.azurestaticapps.net:        azure_static_web_apps_partitioned_2
  # - privatelink.3.azurestaticapps.net:        azure_static_web_apps_partitioned_3
  # - privatelink.4.azurestaticapps.net:        azure_static_web_apps_partitioned_4
  # - privatelink.5.azurestaticapps.net:        azure_static_web_apps_partitioned_5

  # Reference: https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns

}

module "private_dns_zones" {
  source  = "Azure/avm-ptn-network-private-link-private-dns-zones/azurerm"
  version = var.avm-ptn-network-private-link-private-dns-zones_version # "0.23.0" added additional zones; check before upgrade

  parent_id = azapi_resource.resource_group.id

  # location here is "just" to find the correct replacement for the zone's location parts
  #     it uses data "azapi_resource_action" "locations"
  #     Microsoft.Resources/subscriptions@2023-07-01 --> action locations
  location = lower(var.azure_location)


  private_link_excluded_zones = []
  # private_link_private_dns_zones <<== leave default values
  # private_link_private_dns_zones = {}
  private_link_private_dns_zones_additional = {
    for key, val in local.additional_private_dns_zones : key => {
      zone_name                              = val.zone_name
      private_dns_zone_supports_private_link = true
    }
  }

  private_link_private_dns_zones_regex_filter = {
    enabled      = var.private_link_private_dns_zones_regex_filter != null
    regex_filter = var.private_link_private_dns_zones_regex_filter != null ? var.private_link_private_dns_zones_regex_filter : null
  }

  resource_group_role_assignments = null

  virtual_network_link_default_virtual_networks = {
    for vnetid in var.virtual_network_link_id_list : basename(vnetid) => {
      virtual_network_resource_id = vnetid
    }
  }
  virtual_network_link_resolution_policy_default = "NxDomainRedirect"

  enable_telemetry = false

  tags = var.azure_tags
}
