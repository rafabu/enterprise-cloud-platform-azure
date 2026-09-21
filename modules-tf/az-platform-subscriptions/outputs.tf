output "launchpad_subscription" {
  description = "Subscription details including tags and metadata"
  value       = try(module.launchpad_subscription["this"].subscription, null)
}

output "management_subscription" {
  description = "Subscription details including tags and metadata"
  value       = module.management_subscription["this"].subscription
}

output "connectivity_subscription" {
  description = "Subscription details including tags and metadata"
  value       = try(module.connectivity_subscription["this"].subscription, null)
}

output "identity_subscription" {
  description = "Subscription details including tags and metadata"
  value       = try(module.identity_subscription["this"].subscription, null)
}

output "security_subscription" {
  description = "Subscription details including tags and metadata"
  value       = try(module.security_subscription["this"].subscription, null)
}
