locals {
  backend_levels = [
    "l0", # bootstrap
    "l1",
    "l2",
    "l3"
  ]

  backend_type = {
    for key in local.backend_levels : key => length(data.azurerm_resources.backend_storage_accounts[key].resources) == 1 ? "azurerm" : "local"
  }
  # flag to indicate if the backend type has changed between apply runs
  backend_type_changed = {
    for key in local.backend_levels : key => try(var.launchpad_backend_type_previous_run[key].backend_type, "local") != local.backend_type[key] ? true : false
  }
}

data "azurerm_client_config" "this" {
  provider = azurerm.launchpad
}

data "azuread_client_config" "this" {}

data "azuread_directory_object" "this" {
  object_id = data.azuread_client_config.this.object_id
}

data "azuread_users" "this" {
  object_ids = data.azuread_directory_object.this.type == "User" ? [data.azuread_directory_object.this.object_id] : []
}

data "azuread_service_principals" "this" {
  object_ids = data.azuread_directory_object.this.type == "ServicePrincipal" ? [data.azuread_directory_object.this.object_id] : []
}

###### Simulated (future) backend infrastructure ######
data "azurerm_resources" "backend_storage_accounts" {
  for_each = toset(local.backend_levels)

  provider = azurerm.launchpad

  type = "Microsoft.Storage/storageAccounts"
  name = format("%s%s", data.azurecaf_name.st.result, each.key)
}

# Blob Private Endpoint details
data "azapi_resource_list" "backend_storage_account_pep_blob" {

  type      = "Microsoft.Network/privateEndpoints@2025-05-01"
  parent_id = "/subscriptions/${data.azurerm_client_config.this.subscription_id}"

  response_export_values = [
    "value"
  ]
}

locals {
  backend_storage_account_pep_blob_detail = {
    for key, attr in try(data.azapi_resource_list.backend_storage_account_pep_blob.output.value, {}) : attr.name => {
      id         = attr.id
      name       = attr.name
      location   = attr.location
      properties = attr.properties
    }
  }
}

# PowerShell-based public IP detection with multiple sources and retry logic
data "external" "public_ip_robust" {
  program = ["pwsh",
    "-File",
    "${path.module}/Get-PublicIPAddress.ps1"
  ]

  query = null
}

data "external" "this_local_ip" {
  program = ["pwsh",
    "-File",
    "${path.module}/Get-LocalIPAddress.ps1"
  ]

  query = null
}

data "external" "pep_blob_name_resolution" {
  for_each = toset(local.backend_levels)

  program = ["pwsh",
    "-File",
    "${path.module}/Get-LocalNameResolution.ps1"
  ]

  query = {
    fqdn = try(
      local.backend_storage_account_pep_blob_detail[format("%s%s-pep-blob", data.azurecaf_name.st.result, each.key)].properties.customDnsConfigs[0].fqdn,
      ""
    )
    ips = jsonencode(try(
      local.backend_storage_account_pep_blob_detail[format("%s%s-pep-blob", data.azurecaf_name.st.result, each.key)].properties.customDnsConfigs[0].ipAddresses,
      []
    ))
  }
}
