$sku_family = "standardBasv2Family"
$location = "swItzerlandnorth"
$subscription = "e1b3be0d-0df0-4e0a-a585-ffc97f60bd42"

$result = az rest --method get --url "https://management.azure.com/subscriptions/$subscription/providers/Microsoft.DevOpsInfrastructure/locations/$location/usages?api-version=2024-04-04-preview" | ConvertFrom-Json
 
$usage = $result.value | Where-Object { $_.name.value -ieq $sku_family } | Select-Object -First 1
if (-not $usage) {
    throw "SKU family '$sku_family' not found in usage data"
}
# Return flat string values
@{
    sku_family           = $usage.name.value
    sku_family_localized = $usage.name.localizedValue
    subscription         = $subscription
    location             = $location
    current_value        = $usage.currentValue.ToString()
    limit                = $usage.limit.ToString()
    unit                 = $usage.unit
} | ConvertTo-Json -Compress