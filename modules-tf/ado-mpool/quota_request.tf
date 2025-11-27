# need to get the actual quota usages via Microsoft.DevOpsInfrastructure/locations/usages
#     currently that kind of quota cannot be queried directly via GET on Microsoft.Quota/quotas
data "azapi_resource_action" "provider_usage" {
  type = "Microsoft.DevOpsInfrastructure/locations@2024-04-04-preview"
  resource_id            = "${data.azapi_client_config.this.subscription_resource_id}/providers/Microsoft.DevOpsInfrastructure/locations/${var.azure_location}"
  action                 = "usages"
  method                 = "GET"
  response_export_values = ["*"]
}

output "zzz_quota_check" {
  description = "Debug output of ADO managed pool quota check"
  value = {
    output = { for family in data.azapi_resource_action.provider_usage.output.value : family.name.value => family if family.name.value == "standardDSv5Family" },
    id     = data.azapi_resource_action.provider_usage.id
  }
}

locals {
  # current usage of SKU family and details on the allotment required by this mpool instance
  managed_devops_pool_sku                 = local.managed_devops_pool_properties.fabricProfile.sku.name
  managed_devops_pool_sku_family          = "${join("", regexall("^([^_]+)_([A-Za-z]+)\\d+([A-Za-z]*)_(.+)$", local.managed_devops_pool_sku)[0])}Family"
  managed_devops_pool_sku_cpu_count       = tonumber(try(regexall("^[^_]+_[A-Za-z]+(\\d+)[A-Za-z]*_.+$", local.managed_devops_pool_sku)[0][0], 0))
  managed_devops_pool_sku_cpu_count_total = local.managed_devops_pool_properties.maximumConcurrency * local.managed_devops_pool_sku_cpu_count
  managed_devops_pool_usage = try([
    for usage in data.azapi_resource_action.provider_usage.output.value :
    {
      usage                    = usage
      limit                    = usage.limit
      current_usage            = usage.currentValue
      sku_family               = usage.name.value
      sku_family_localized     = usage.name.localizedValue
      this_sku_family          = local.managed_devops_pool_sku
      this_sku_cpu_count       = local.managed_devops_pool_sku_cpu_count
      this_sku_cpu_count_total = local.managed_devops_pool_sku_cpu_count_total
      this_has_room            = usage.currentValue + local.managed_devops_pool_sku_cpu_count_total <= usage.limit ? true : false
      this_missing_cpu_count   = usage.currentValue + local.managed_devops_pool_sku_cpu_count_total > usage.limit ? (usage.currentValue + local.managed_devops_pool_sku_cpu_count_total) - usage.limit : 0
    }
    if lower(usage.name.value) == lower(local.managed_devops_pool_sku_family)
  ][0], {})
}

output "zzz_managed_devops_pool_usage" {
  description = "Debug output of current managed devops pool usage"
  value       = local.managed_devops_pool_usage
}


resource "terraform_data" "managed_devops_pool_usage" {
  triggers_replace = {
    # force re-evaluation when relevant inputs change
    managed_devops_pool_sku                 = local.managed_devops_pool_sku
    managed_devops_pool_sku_cpu_count_total = local.managed_devops_pool_sku_cpu_count_total
    this_missing_cpu_count                  = local.managed_devops_pool_usage.this_missing_cpu_count
  }
}

locals {
  quota_request_set_url = "${data.azapi_client_config.this.subscription_resource_id}/providers/Microsoft.DevOpsInfrastructure/locations/${var.azure_location}/providers/Microsoft.Quota/quotas/${local.managed_devops_pool_usage.sku_family}"
  # as /Microsoft.DevOpsInfrastructure does not (yet) support GET; fall back to using Microsoft.Compute
  quota_request_get_url = "${data.azapi_client_config.this.subscription_resource_id}/providers/Microsoft.Compute/locations/${var.azure_location}/providers/Microsoft.Quota/quotas/standardFSFamily"
}

# the SET operation on this is extremely sensitive to throttling; make sure it doesn't run too often!!!
#     if no increase is required, just do a GET to satisfy TF resource requirements, which currently returns an empty list
resource "azapi_resource_action" "provider_quota_request" {
  type        = "Microsoft.Quota/quotas@2025-09-01"
  resource_id = local.managed_devops_pool_usage.this_has_room == true ? local.quota_request_set_url : local.quota_request_get_url

  # post only when INCREASE is required; otherwise just do a GET to satisfy TF resource requirements
  action = ""
  method = local.managed_devops_pool_usage.this_has_room == true ? "POST" : "GET"
  body = local.managed_devops_pool_usage.this_has_room == true ? {
    properties = {
      name = {
        value = local.managed_devops_pool_usage.sku_family
      }
      limit = {
        limitObjectType = "LimitValue"
        value           = local.managed_devops_pool_usage.limit + local.managed_devops_pool_usage.this_missing_cpu_count
      }
      # properties = {
      #   requestOrigin = "Microsoft_Azure_Capacity/QuotaApproval.ReactView"
      # }
    }
  } : {}

  response_export_values = [
    "*"
  ]

  lifecycle {
    ignore_changes = all
  }

  depends_on = [
    terraform_data.managed_devops_pool_usage
  ]
}

output "zzz_quota_request" {
  description = "Debug output of ADO managed pool quota request"
  value = {
    id     = azapi_resource_action.provider_quota_request.id
    output = azapi_resource_action.provider_quota_request.output
  }
}
