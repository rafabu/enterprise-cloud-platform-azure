##################################################    Service Connection    ################################################## 
locals {
  uami_subscription_id   = provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30", azapi_resource.project_uami.id).subscription_id
  uami_subscription_name = data.azapi_resource.lz_subscription.output.displayName
}

data "azapi_resource" "lz_subscription" {
  type                   = "Microsoft.Resources/subscriptions@2022-12-01"
  resource_id            = "/subscriptions/${local.uami_subscription_id}"
  response_export_values = ["displayName"]
}

resource "azuredevops_serviceendpoint_azurerm" "this" {
  project_id                             = azuredevops_project.this.id
  service_endpoint_name                  = var.service_connection_name
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  description                            = "Managed by ECP LZ Vending DevOps"
  credentials {
    serviceprincipalid = azapi_resource.project_uami.output.properties.clientId
  }
  azurerm_spn_tenantid      = data.azapi_client_config.current.tenant_id
  azurerm_subscription_id   = local.uami_subscription_id
  azurerm_subscription_name = local.uami_subscription_name

  lifecycle {
    ignore_changes = [
      description,
    ]
  }
}

# grant access to service endpoint for all pipelines in the project
resource "azuredevops_pipeline_authorization" "this" {
  project_id  = azuredevops_project.this.id
  resource_id = azuredevops_serviceendpoint_azurerm.this.id
  type        = "endpoint"
  # authorized  = true
}

resource "azapi_resource" "federated_identity_credential" {
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2024-11-30"
  name      = replace("Azure-DevOps_${data.azuredevops_client_config.current.name}_${azuredevops_project.this.name}", " ", "_")
  parent_id = azapi_resource.project_uami.id

  body = {
    properties = {
      audiences = ["api://AzureADTokenExchange"]
      issuer    = azuredevops_serviceendpoint_azurerm.this.workload_identity_federation_issuer
      subject   = azuredevops_serviceendpoint_azurerm.this.workload_identity_federation_subject
    }
  }
}

resource "azapi_resource" "federated_identity_credential_lock" {
  type      = "Microsoft.Authorization/locks@2020-05-01"
  name      = "${azapi_resource.federated_identity_credential.name}-cannotdelete"
  parent_id = azapi_resource.federated_identity_credential.id

  body = {
    properties = {
      level = "CanNotDelete"
      notes = "Prevents accidental deletion of the DevOps project federated identity credential"
    }
  }
}
