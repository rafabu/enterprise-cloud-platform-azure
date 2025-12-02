# need to get the actual quota usages via Microsoft.DevOpsInfrastructure/locations/usages
#     currently that kind of quota cannot be queried directly via GET on Microsoft.Quota/quotas
data "azapi_resource_action" "provider_usage" {
  type                   = "Microsoft.DevOpsInfrastructure/locations@2024-04-04-preview"
  resource_id            = "${data.azapi_client_config.this.subscription_resource_id}/providers/Microsoft.DevOpsInfrastructure/locations/${lower(var.azure_location)}"
  action                 = "usages"
  method                 = "GET"
  response_export_values = ["*"]

  depends_on = [
    data.azapi_resource.provider_registration_recheck
  ]
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

resource "terraform_data" "managed_devops_quota_request" {
  triggers_replace = {
    # force re-evaluation when relevant inputs change
    managed_devops_pool_sku                 = local.managed_devops_pool_sku
    managed_devops_pool_sku_cpu_count_total = local.managed_devops_pool_sku_cpu_count_total
  }

  # the SET operation on this is extremely sensitive to throttling; make sure it doesn't run too often!!!
  #     if no increase is required, just do a GET (on another provider) to satisfy TF resource requirements

  provisioner "local-exec" {
    when        = create
    interpreter = ["pwsh", "-NoLogo", "-NonInteractive", "-ExecutionPolicy", "RemoteSigned", "-command"]
    command     = <<-SCRIPT
      $ErrorActionPreference = 'Continue'
      try {
        # this works - but doesn't report on success :-(
        az quota update --resource-name "${local.managed_devops_pool_usage.sku_family}" --scope "${local.quota_request_scope}" --limit-object value=${local.managed_devops_pool_usage.limit + local.managed_devops_pool_usage.this_missing_cpu_count} 2>&1 | Out-Null
        Write-Output "Quota request completed (exit code: $LASTEXITCODE) - note: non zero exit code is expected..."
      }
      catch {
        Write-Output "Quota request completed with error (expected): $($_.Exception.Message)"
      }
      # need to wait for replication of quota after changing it
      Write-Output "Waiting 30 seconds for quota change replication..."
      Start-Sleep -Seconds 30
      exit 0
    SCRIPT
  }
}

locals {
  quota_request_scope = "${data.azapi_client_config.this.subscription_resource_id}/providers/Microsoft.DevOpsInfrastructure/locations/${lower(var.azure_location)}"
  quota_request_id = "${data.azapi_client_config.this.subscription_resource_id}/providers/Microsoft.DevOpsInfrastructure/locations/${lower(var.azure_location)}/providers/Microsoft.Quota/quotas/${local.managed_devops_pool_usage.sku_family}"
}

data "azapi_resource_action" "provider_usage_recheck" {
  type                   = "Microsoft.DevOpsInfrastructure/locations@2024-04-04-preview"
  resource_id            = "${data.azapi_client_config.this.subscription_resource_id}/providers/Microsoft.DevOpsInfrastructure/locations/${lower(var.azure_location)}"
  action                 = "usages"
  method                 = "GET"
  response_export_values = ["*"]

  depends_on = [
    terraform_data.managed_devops_quota_request
  ]

  lifecycle {

    postcondition {
      condition = [
        for usage in self.output.value : usage.limit
        if lower(usage.name.value) == lower(local.managed_devops_pool_sku_family)
      ][0] >= local.managed_devops_pool_usage.limit + local.managed_devops_pool_usage.this_missing_cpu_count
      error_message = "Microsoft.DevOpsInfrastructure quota request for ${local.managed_devops_pool_sku_family} in region ${lower(var.azure_location)} has not been fulfilled; current limit is still insufficient."
    }
  }
}

locals {
  managed_devops_pool_usage_finally = try([
    for usage in data.azapi_resource_action.provider_usage_recheck.output.value :
    {
      limit                = usage.limit
      current_usage        = usage.currentValue
      sku_family           = usage.name.value
      sku_family_localized = usage.name.localizedValue
    }
    if lower(usage.name.value) == lower(local.managed_devops_pool_sku_family)
  ][0], {})
}
