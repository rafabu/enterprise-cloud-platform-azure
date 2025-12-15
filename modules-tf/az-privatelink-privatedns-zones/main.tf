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
    #     - avm-ptn-network-private-link-private-dns-zones version 0.22.2
    #     - Deploy-Private-DNS-Zones version 2.4.0
    #      https://github.com/Azure/terraform-azurerm-avm-ptn-network-private-link-private-dns-zones
    #      https://github.com/Azure/Azure-Landing-Zones-Library/blob/main/platform/alz/policy_set_definitions/Deploy-Private-DNS-Zones.alz_policy_set_definition.json
    azure_chaos_studio = {
      zone_name = "privatelink.chaos-studio.azure.com"
    }
    azure_deployment_environments = {
      zone_name = "privatelink.devcenter.azure.com"
    }
  }
  # missing from ALZ policy 2.4.0 but present in AVM 0.22.2:
  # - privatelink.openai.azure.com
  # - privatelink.mysql.database.azure.com
  # - privatelink.postgres.database.azure.com
  # - privatelink.purview.azure.com
  # - privatelink.purviewstudio.azure.com
  # - privatelink.grafana.azure.com
  # - privatelink.azurestaticapps.net
  # - privatelink.fhir.azurehealthcareapis.com
  # - privatelink.dicom.azurehealthcareapis.com
}


module "private_dns_zones" {
  source  = "Azure/avm-ptn-network-private-link-private-dns-zones/azurerm"
  version = "0.22.2"

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
