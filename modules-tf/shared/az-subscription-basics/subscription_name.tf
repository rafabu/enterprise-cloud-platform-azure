resource "azapi_resource_action" "subscription_name" {
  for_each = toset(length(var.subscription_name) > 0 ? ["this"] : [])

  type        = "Microsoft.Resources/subscriptions@2021-10-01"
  resource_id = "/subscriptions/${var.subscription_id}"
  action      = "providers/Microsoft.Subscription/rename"
  method      = "POST"
  body = {
    subscriptionName = var.subscription_name
  }
}
