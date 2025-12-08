output "subscription" {
  description = "Subscription Details"
  value = {
    id              = var.subscription_id
    subscription_id = "/subscriptions/${var.subscription_id}"
    name            = var.subscription_name
    tags            = var.tags
    read_only_tags  = var.read_only_tags
  }
}
