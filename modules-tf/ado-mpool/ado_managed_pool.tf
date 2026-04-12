locals {
  managed_devops_pool_properties = {
    maximumConcurrency = var.managed_devops_pool_maximum_concurrency
    agentProfile = {
      kind = "Stateless"
      resourcePredictions = try(var.managed_devops_pool_stateless_agent_profile.manual_resource_predictions_profile, null) != null && length(try(var.managed_devops_pool_stateless_agent_profile.manual_resource_predictions_profile, {})) > 0 ? {
        timeZone = coalesce(var.managed_devops_pool_stateless_agent_profile.manual_resource_predictions_profile.time_zone, "UTC")
        daysData = coalesce(var.managed_devops_pool_stateless_agent_profile.manual_resource_predictions_profile.all_week_schedule, 0) > 0 ? [
          {
            "00:00:00" : var.managed_devops_pool_stateless_agent_profile.manual_resource_predictions_profile.all_week_schedule
          }
          ] : [
          {
            for t, v in try(var.managed_devops_pool_stateless_agent_profile.manual_resource_predictions_profile.sunday_schedule, {}) : t => v
          },
          {
            for t, v in try(var.managed_devops_pool_stateless_agent_profile.manual_resource_predictions_profile.monday_schedule, {}) : t => v
          },
          {
            for t, v in try(var.managed_devops_pool_stateless_agent_profile.manual_resource_predictions_profile.tuesday_schedule, {}) : t => v
          },
          {
            for t, v in try(var.managed_devops_pool_stateless_agent_profile.manual_resource_predictions_profile.wednesday_schedule, {}) : t => v
          },
          {
            for t, v in try(var.managed_devops_pool_stateless_agent_profile.manual_resource_predictions_profile.thursday_schedule, {}) : t => v
          },
          {
            for t, v in try(var.managed_devops_pool_stateless_agent_profile.manual_resource_predictions_profile.friday_schedule, {}) : t => v
          },
          {
            for t, v in try(var.managed_devops_pool_stateless_agent_profile.manual_resource_predictions_profile.saturday_schedule, {}) : t => v
          }
        ]
      } : null
      resourcePredictionsProfile = {
        kind                 = try(var.managed_devops_pool_stateless_agent_profile.automatic_resource_predictions_profile, null) != null && length(try(var.managed_devops_pool_stateless_agent_profile.automatic_resource_predictions_profile, {})) > 0 ? "Automatic" : "Manual"
        predictionPreference = try(var.managed_devops_pool_stateless_agent_profile.automatic_resource_predictions_profile, null) != null && length(try(var.managed_devops_pool_stateless_agent_profile.automatic_resource_predictions_profile, {})) > 0 ? coalesce(var.managed_devops_pool_stateless_agent_profile.automatic_resource_predictions_profile.prediction_preference, "Balanced") : null
      }
    }
    fabricProfile = {
      sku = {
        # Default Managed_DevOps_Pool: "Standard_D2ds_v5"
        # AMD EPYC 9654 (Genoa)
        name = coalesce(var.managed_devops_pool_vmss_fabric_profile.sku_name, "Standard_D2as_v5") # --> Standard_D*as_v6 is compatible (v2 VM image only)
      }
      images = [for img in try(var.managed_devops_pool_vmss_fabric_profile.image, {
        aliases            = ["ubuntu-24.04-g2"]
        buffer             = "*"
        wellKnownImageName = "ubuntu-24.04-g2/latest"
        }) : {

        aliases            = try(img.aliases, [img.well_known_image_name])
        buffer             = coalesce(img.buffer, "*")
        wellKnownImageName = img.well_known_image_name
        }
      ]
      osProfile = {
        logonType = coalesce(var.managed_devops_pool_vmss_fabric_profile.os_profile.logon_type, "Service")
      }
      storageProfile = {
        osDiskStorageAccountType = coalesce(var.managed_devops_pool_vmss_fabric_profile.storage_profile.os_disk_storage_account_type, "StandardSSD") # "Standard" / "Premium"
        dataDisks                = try(var.managed_devops_pool_vmss_fabric_profile.storage_profile.data_disk, [])
      }
      networkProfile = {
        # static ip address is only needed if pool is not subnet integrated
        staticIpAddressCount = length(var.subnet_artefact_names) == 0 ? 1 : 0
        subnetId             = length(var.subnet_artefact_names) > 0 ? azurerm_subnet.mpool[var.subnet_artefact_names[0]].id : null
      }
    }
  }
}

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
      maximumConcurrency         = local.managed_devops_pool_properties.maximumConcurrency
      organizationProfile = {
        kind = "AzureDevOps"
        organizations = [
          {
            url = "https://dev.azure.com/${var.ecp_azure_devops_organization_name}"
            projects = [
              var.ecp_azure_devops_project_name
            ]
            parallelism = local.managed_devops_pool_properties.maximumConcurrency
            openAccess  = false
          }
        ]
        permissionProfile = {
          kind = "CreatorOnly"
        }
      }
      agentProfile = {
        kind                = local.managed_devops_pool_properties.agentProfile.kind
        resourcePredictions = local.managed_devops_pool_properties.agentProfile.resourcePredictions
        resourcePredictionsProfile = local.managed_devops_pool_properties.agentProfile.resourcePredictionsProfile.kind == "Automatic" ? {
          kind                 = "Automatic" #local.managed_devops_pool_properties.agentProfile.resourcePredictionsProfile.kind
          predictionPreference = local.managed_devops_pool_properties.agentProfile.resourcePredictionsProfile.predictionPreference
          } : {
          kind = "Manual"
        }
      }
      fabricProfile = {
        sku = {
          name = try(local.managed_devops_pool_properties.fabricProfile.sku.name, "Standard_D2ds_v5")
        }
        images = local.managed_devops_pool_properties.fabricProfile.images

        networkProfile = {
          # public IP address to allow outbound connections from the pool VMs in subnets without default outbound access
          staticIpAddressCount = local.managed_devops_pool_properties.fabricProfile.networkProfile.staticIpAddressCount
          subnetId             = local.managed_devops_pool_properties.fabricProfile.networkProfile.subnetId
        }
        osProfile = {
          logonType = local.managed_devops_pool_properties.fabricProfile.osProfile.logonType
        }
        storageProfile = {
          osDiskStorageAccountType = local.managed_devops_pool_properties.fabricProfile.storageProfile.osDiskStorageAccountType
          dataDisks                = local.managed_devops_pool_properties.fabricProfile.storageProfile.dataDisks
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
    azurerm_role_assignment.devops_infrastructure_vnet,
    azurerm_subnet_nat_gateway_association.mpool,
    data.azapi_resource_action.provider_usage_recheck
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
