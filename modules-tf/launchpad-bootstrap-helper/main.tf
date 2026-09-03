locals {
  backend_levels = [
    "l0", # bootstrap
    "l1",
    "l2",
    "l3"
  ]

  backend_storage_account_present_list = [
    for key in local.backend_levels : {
      for st in try(data.azapi_resource_list.backend_storage_accounts.output.value, []) : key => {
        id                  = st.id
        name                = st.name
        resource_group_name = provider::azapi::parse_resource_id("Microsoft.Storage/storageAccounts", st.id).resource_group_name
        location            = st.location
      }
      if st.name == format("%s%s", data.azurecaf_name.st.result, key)
    }
  ]

  backend_storage_account_present_details = zipmap(
    flatten([for entry, attr in local.backend_storage_account_present_list : keys(attr)]),
    flatten([for entry, attr in local.backend_storage_account_present_list : values(attr)])
  )

  backend_type = {
    for key in local.backend_levels : key => length(try(local.backend_storage_account_present_details[key].id, "")) > 0 ? "azurerm" : "local"
  }

  # flag to indicate if the backend type has changed between consequent apply runs on the the same machine (e.g. during bootstrapping)
  backend_type_changed = {
    for key in local.backend_levels : key => try(var.launchpad_backend_type_previous_run[key].backend_type, "local") != local.backend_type[key] ? true : false
  }
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
data "azapi_resource_list" "backend_storage_accounts" {
  # for_each = toset(local.backend_levels)

  type      = "Microsoft.Storage/storageAccounts@2026-04-01"
  parent_id = "/subscriptions/${var.ecp_launchpad_subscription_id}"

  response_export_values = {
    value = "value[].{name: name, id: id, kind: kind, location: location}"
  }
}

# Blob Private Endpoint details
data "azapi_resource_list" "backend_storage_account_pep_blob" {

  type      = "Microsoft.Network/privateEndpoints@2026-01-01"
  parent_id = "/subscriptions/${var.ecp_launchpad_subscription_id}"

  response_export_values = [
    "value"
  ]
}

data "azapi_resource_list" "backend_storage_account_pep_nic_blob" {

  type      = "Microsoft.Network/networkInterfaces@2026-01-01"
  parent_id = "/subscriptions/${var.ecp_launchpad_subscription_id}"

  response_export_values = {
    value = "value[].{name: name, id: id, privateIPAddress: properties.ipConfigurations[0].properties.privateIPAddress, fqdn: properties.ipConfigurations[0].properties.privateLinkConnectionProperties.fqdns[0], privateEndpointId: properties.privateEndpoint.id}"
  }
}

locals {
  backend_storage_account_pep_blob_details = {
    for key, attr in try(data.azapi_resource_list.backend_storage_account_pep_blob.output.value, {}) : attr.name => {
      id         = attr.id
      name       = attr.name
      location   = attr.location
      properties = attr.properties
      privateEndpointNIC = try([
        for nic in try(data.azapi_resource_list.backend_storage_account_pep_nic_blob.output.value, []) : {
          id                  = nic.id
          name                = nic.name
          private_ip_address  = nic.privateIPAddress
          fqdn                = nic.fqdn
          private_endpoint_id = nic.privateEndpointId
        }
        if nic.privateEndpointId == attr.id
      ][0], {})
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
      local.backend_storage_account_pep_blob_details[format("%s%s-pep-blob", data.azurecaf_name.st.result, each.key)].privateEndpointNIC.fqdn,
      ""
    )
    ips = jsonencode(try(
      local.backend_storage_account_pep_blob_details[format("%s%s-pep-blob", data.azurecaf_name.st.result, each.key)].privateEndpointNIC.private_ip_address,
      []
    ))
  }
}
