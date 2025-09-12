resource "azapi_resource" "dev_center" {

  type = "Microsoft.DevCenter/devcenters@2025-02-01"
  # managed devops pool does not (yet) exist in provider DS - just rename the RG one...
  name      = replace(data.azurecaf_name.rg.result, "-rg-", "-devc-")
  parent_id = data.azapi_resource_id.resource_group.id

  identity {
    type = "systemAssignedIdentity"
  }
  location = var.azure_location
  tags     = var.azure_location

  body = {
    properties = {
      devBoxProvisioningSettings = {
        installAzureMonitorAgentEnableStatus = "Enabled"
      }
      displayName = replace(data.azurecaf_name.rg.result, "-rg-", "-devc-")
      encryption  = null
      networkSettings = {
        # pools will need self-hosted network
        microsoftHostedNetworkEnableStatus = "Disabled"
      }
      projectCatalogSettings = {
        catalogItemSyncEnableStatus = "Enabled"
      }
    }
  }
}

resource "azapi_resource" "dev_center_project" {

  # managed devops project does not (yet) exist in provider DS - just rename the RG one...
  name      = replace(data.azurecaf_name.rg.result, "-rg-", "-devcproj-")
  parent_id = data.azapi_resource_id.resource_group.id

  identity {
    type = "systemAssignedIdentity"
  }
  location = var.azure_location
  tags     = var.azure_location

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

      description = "ECP Launchpad Project"

      devBoxAutoDeleteSettings = {
        deleteMode        = "string"
        gracePeriod       = "string"
        inactiveThreshold = "string"
      }
      devCenterId = azapi_resource.dev_center.id
      displayName = replace(data.azurecaf_name.rg.result, "-rg-", "-devcproj-")

      maxDevBoxesPerUser = 1
      serverlessGpuSessionsSettings = {
        maxConcurrentSessionsPerProject = 1
        serverlessGpuSessionsMode       = "Disabled"
      }
      workspaceStorageSettings = {
        workspaceStorageMode = "Disabled"
      }
    }
  }
}
