# $header = @{
#     "Content-Type" = "application/json"
# }

$subscriptionId = "e1b3be0d-0df0-4e0a-a585-ffc97f60bd42"
$location = "switzerlandnorth"
$provider = "Microsoft.DevOpsInfrastructure"
$skuFamily = "standardDASv5Family"
$skuFamily = "standardDDv5Family"
$skuFamily = "standardDASv4Family"
$value = 4


# --> does not work:
#     az quota usage show  --scope "/subscriptions/$subscriptionId/providers/$provider/locations/$location" --resource-name "$skuFamily"

# this works - but doesn't report on success :-(
az quota update --resource-name "$skuFamily" --scope "/subscriptions/$subscriptionId/providers/$provider/locations/$location" --limit-object value=$value # --no-wait # --debug


$requestBody = @{
    properties = @{
        limit = @{
            limitObjectType = "LimitValue"
            value           = $value
        }
        name  = @{
            value = $skuFamily
        }
    }
} | ConvertTo-Json -Depth 10

# # Write-Output $header
# Write-Output $requestBody

# az rest --method put --url "https://management.azure.com/subscriptions/$subscriptionId/providers/$provider/locations/$location/providers/Microsoft.Quota/quotas/$($skuFamily)?api-version=2025-09-01" `
#     --body "@-" # $requestBody
