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

resource "azapi_resource" "managed_devops_pool" {
  # managed devops pool does not (yet) exist in provider DS - just rename the RG one...
  name      = replace(data.azurecaf_name.rg.result, "-rg-", "-mpool-")
  parent_id = azurerm_resource_group.mpool.id
  type      = "Microsoft.DevOpsInfrastructure/pools@2025-09-20"
  location  = azurerm_resource_group.mpool.location
  body = {
    properties = {
      devCenterProjectResourceId = var.dev_center_project_resource_id
      maximumConcurrency         = 2
      organizationProfile = {
        kind = "AzureDevOps"
        organizations = [
          {
            url = "https://dev.azure.com/${var.ecp_azure_devops_organization_name}"
            projects = [
              var.ecp_azure_devops_project_name
            ]
            parallelism = 2
            openAccess  = false
          }
        ]
        permissionProfile = {
          kind = "CreatorOnly"
        }
      }

      agentProfile = {
        kind = "Stateless"
        resourcePredictions = {
          timeZone = "W. Europe Standard Time",
          daysData = [
            {},
            {
              "07:30:00" = 2,
              "21:00:00" = 0
            },
            {
              "07:30:00" = 2,
              "21:00:00" = 0
            },
            {
              "07:30:00" = 2,
              "21:00:00" = 0
            },
            {
              "07:30:00" = 2,
              "21:00:00" = 0
            },
            {
              "07:30:00" = 2,
              "21:00:00" = 0
            },
            {}
          ]
        },
        resourcePredictionsProfile = {
          kind = "Manual"
        }
      }

      fabricProfile = {
        sku = {
          name = "Standard_B2as_v2" # Default: "Standard_D2ds_v5"
        }
        images = [
          {
            wellKnownImageName = "ubuntu-24.04/latest"
            aliases = [
              "ubuntu-24.04/latest"
            ]
            buffer     = "*"
            resourceId = null
          }
        ]

        networkProfile = {
          subnetId = azurerm_subnet.mpool[var.subnet_artefact_names[0]].id
        }
        osProfile = {
          logonType = "Service"
        }
        storageProfile = {
          osDiskStorageAccountType = "StandardSSD"
          dataDisks                = []
        }
        kind = "Vmss"
      }
    }
  }

  tags = var.azure_tags

  schema_validation_enabled = true

  depends_on = [
    azuredevops_group_membership.mpool,
    azuredevops_group_membership.mpool_project,
    azurerm_role_assignment.devops_infrastructure_vnet
  ]
}

# set pool permissions (authorizations on queue and all pipelines in the project (pre-authorize))
data "azuredevops_agent_pool" "mpool" {
  name = azapi_resource.managed_devops_pool.name
}

data "azuredevops_agent_queue" "mpool" {
  project_id = local.azure_devops_project.project_id
  name       = azapi_resource.managed_devops_pool.name
}

resource "azuredevops_pipeline_authorization" "agent_queue_shared" {
  project_id  = local.azure_devops_project.project_id
  resource_id = data.azuredevops_agent_queue.mpool.id
  type        = "queue"

  lifecycle {
    ignore_changes = all
  }
}

