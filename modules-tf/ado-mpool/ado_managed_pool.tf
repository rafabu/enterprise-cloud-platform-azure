# DevOpsInfrastructure service principal needs "Reader" and "Network Contributor"
data "azuread_service_principal" "devops_infrastructure" {
  # DevOpsInfrastructure (MS-SPI)
  client_id = "31687f79-5e43-4c1e-8c63-d9f4bff5cf8b"

  depends_on = [
    data.azapi_resource.provider_registration_recheck
  ]
}

resource "azurerm_role_assignment" "devops_infrastructure_vnet" {
  provider = azurerm.launchpad

  for_each = toset([
    "acdd72a7-3385-48ef-bd42-f606fba81ae7",
    "4d97b98b-1d4f-4787-a291-c67834d212e7"
  ])

  scope              = var.virtual_network_id
  role_definition_id = "${data.azapi_client_config.this.subscription_resource_id}/providers/Microsoft.Authorization/roleDefinitions/${each.key}"
  principal_id       = data.azuread_service_principal.devops_infrastructure.object_id
}

module "managed_devops_pool" {
  providers = {
    azurerm = azurerm.launchpad
    azapi   = azapi
  }

  source  = "Azure/avm-res-devopsinfrastructure-pool/azurerm"
  version = "0.3.1"

  # managed devops pool does not (yet) exist in provider DS - just rename the RG one...
  name = replace(data.azurecaf_name.rg.result, "-rg-", "-mpool-")
  resource_group_name = azurerm_resource_group.mpool.name
  location            = azurerm_resource_group.mpool.location

  dev_center_project_resource_id           = var.dev_center_project_resource_id
  version_control_system_organization_name = var.ecp_azure_devops_organization_name
  version_control_system_project_names = [
    var.ecp_azure_devops_project_name
  ]
  version_control_system_type = "azuredevops"
  subnet_id                   = azurerm_subnet.mpool[var.subnet_artefact_names[0]].id

  agent_profile_resource_prediction_profile = "Manual"
  agent_profile_kind                        = "Stateless"
  agent_profile_resource_predictions_manual = {
    time_zone = "W. Europe Standard Time"
    days_data = [
      # Sunday
      {}, # Empty map to skip Sunday
      # Monday
      {
        "07:30:00" = 2
        "21:00:00" = 0
      },
      # Tuesday
      {
        "07:30:00" = 2
        "21:00:00" = 0
      },
      # Wednesday
      {
        "07:30:00" = 2
        "21:00:00" = 0
      },
      # Thursday
      {
        "07:30:00" = 2
        "21:00:00" = 0
      },
      # Friday
      {
        "07:30:00" = 2
        "21:00:00" = 0
      },
      # Saturday
      {} # Empty map to skip Saturday
    ]
  }

  fabric_profile_data_disks = []
  fabric_profile_images = [
    {
      "aliases" : [
        "ubuntu-24.04/latest"
      ],
      "well_known_image_name" : "ubuntu-24.04/latest"
    }
  ]
  fabric_profile_os_disk_storage_account_type = "StandardSSD"
  fabric_profile_os_profile_logon_type        = "Service"
  fabric_profile_sku_name                     = "Standard_B2as_v2" # Default: "Standard_D2ds_v5"

  maximum_concurrency = 2

  tags = var.azure_tags

  depends_on = [
    azuredevops_group_membership.mpool,
    azuredevops_group_membership.mpool_project,
    azurerm_role_assignment.devops_infrastructure_vnet
  ]
}

# set pool permissions (authorizations on queue and all pipelines in the project (pre-authorize))
data "azuredevops_agent_pool" "mpool" {
  name = module.managed_devops_pool.name

  depends_on = [
    module.managed_devops_pool
  ]
}

data "azuredevops_agent_queue" "mpool" {
  project_id = local.azure_devops_project.project_id
  name       = module.managed_devops_pool.name

  depends_on = [
    module.managed_devops_pool
  ]
}

resource "azuredevops_pipeline_authorization" "agent_queue_shared" {
  project_id  = local.azure_devops_project.project_id
  resource_id = data.azuredevops_agent_queue.mpool.id
  type        = "queue"
}

