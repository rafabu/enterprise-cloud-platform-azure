output "subscription" {
  description = "Subscription Details"
  value = {
    id              = var.subscription_id
    subscription_id = azapi_resource_action.subscription_tags.resource_id
    name            = var.subscription_name
    tags            = var.tags
    read_only_tags  = var.read_only_tags
  }
}
