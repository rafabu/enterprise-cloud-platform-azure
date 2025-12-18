locals {

  policy_private_dns_zones_not_in_alz = [
    # DNS zones not (yet) implemented in ALZ 'Deploy-Private-DNS-Zones' policy initiative
    #     as of version 2.4.0
    "azure_aks_mgmt", # AKS private networking does not work with private endpoints but vnet integration
    "azure_attestation",
    "azure_avd_global",
    "azure_bot_svc_token",
    "azure_chaos_studio",
    "azure_container_apps",
    "azure_cosmos_db_analytical",
    "azure_cosmos_db_mongo_vcore",
    "azure_cosmos_db_postgres",
    "azure_data_explorer",
    "azure_deployment_environments",
    "azure_digital_twins",
    "azure_fabric",
    "azure_healthcare",
    "azure_healthcare_dicom",
    "azure_healthcare_fhir",
    "azure_healthcare_workspaces",
    "azure_iot_hub_update",
    "azure_managed_hsm",
    "azure_managed_prometheus",
    "azure_maria_db_server",
    "azure_mysql_db_server",
    "azure_postgres_sql_server",
    "azure_power_bi_dedicated",
    "azure_power_bi_power_query",
    "azure_power_bi_tenant_analysis",
    "azure_purview_account",
    "azure_purview_studio",
    "azure_redis_enterprise",
    "azure_sql_server",
    "azure_static_web_apps",
    "azure_static_web_apps_partitioned_1",
    "azure_static_web_apps_partitioned_2",
    "azure_static_web_apps_partitioned_3",
    "azure_static_web_apps_partitioned_4",
    "azure_static_web_apps_partitioned_5",
    "azure_synapse"
  ]

  policy_default_values_private_dns_zones = {
    for key, val in var.private_dns_zone_configuration :
    "private_dns_zone_id_${key}" => jsonencode(
      {
        value = "${val}"
      }
    )
    if contains(local.policy_private_dns_zones_not_in_alz, key) == false
  }

    policy_default_values_private_dns_zones_not_in_alz = {
    for key, val in var.private_dns_zone_configuration :
    "private_dns_zone_id_${key}" => jsonencode(
      {
        value = "${val}"
      }
    )
    if contains(local.policy_private_dns_zones_not_in_alz, key) == true
  }
}

output "policy_default_values_private_dns_zones_not_in_alz" {
  value = local.policy_default_values_private_dns_zones_not_in_alz
}
