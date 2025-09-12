resource "azapi_resource" "dev_center" {

  type = "Microsoft.DevCenter/devcenters@2025-02-01"
  # managed devops pool does not (yet) exist in provider DS - just rename the RG one...
  name      = replace(data.azurecaf_name.rg.result, "-rg-", "-devc-")
  parent_id = data.azapi_resource.resource_group.id

  identity {
    type = "SystemAssigned"
  }
  location = data.azapi_resource.resource_group.location
  tags     = var.azure_tags

  body = {
    properties = {
      devBoxProvisioningSettings = {
        installAzureMonitorAgentEnableStatus = "Enabled"
      }
      # displayName = "lovely display name"
      encryption = null
      networkSettings = {
        # pools will need self-hosted network
        microsoftHostedNetworkEnableStatus = "Disabled"
      }
      projectCatalogSettings = {
        catalogItemSyncEnableStatus = "Enabled"
      }
    }
  }

  response_export_values = ["name", "id", "location", "identity"]

  lifecycle {
    ignore_changes = [
      tags["hidden-title"]
    ]
  }
}

resource "azapi_resource" "dev_center_project" {

  type = "Microsoft.DevCenter/projects@2025-07-01-preview"
  # managed devops project does not (yet) exist in provider DS - just rename the RG one...
  name      = replace(data.azurecaf_name.rg.result, "-rg-", "-devcproj-")
  parent_id = data.azapi_resource.resource_group.id

  identity {
    type = "SystemAssigned"
  }
  location = data.azapi_resource.resource_group.location
  tags     = var.azure_tags

  body = {
    properties = {
      azureAiServicesSettings = {
        azureAiServicesMode = "Disabled"
      }
      catalogSettings = {
        catalogItemSyncTypes = [
          "EnvironmentDefinition",
          "ImageDefinition"
        ]
      }
      customizationSettings = null

      description = "ECP Launchpad Project ${join("-", var.azure_resource_name_elements.prefixes)}"

      devBoxAutoDeleteSettings = null # {
      #   deleteMode        = "string"
      #   gracePeriod       = "string"
      #   inactiveThreshold = "string"
      # }
      devCenterId = azapi_resource.dev_center.id

      maxDevBoxesPerUser = 1
      serverlessGpuSessionsSettings = {
        maxConcurrentSessionsPerProject = 5
        serverlessGpuSessionsMode       = "Disabled"
      }
      workspaceStorageSettings = {
        workspaceStorageMode = "Disabled"
      }
    }
  }
  response_export_values = ["name", "id", "location", "identity"]

  lifecycle {
    ignore_changes = [
      tags["hidden-title"]
    ]
  }
}
