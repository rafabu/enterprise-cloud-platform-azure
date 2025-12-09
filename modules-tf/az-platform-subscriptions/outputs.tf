output "launchpad_subscription" {
  description = "Subscription details including tags and metadata"
  value       = var.ecp_launchpad_subscription_id != "00000000-0000-0000-0000-000000000000" ? module.launchpad_subscription["this"].subscription : null
}

output "management_subscription" {
  description = "Subscription details including tags and metadata"
  value       = var.ecp_management_subscription_id != "00000000-0000-0000-0000-000000000000" ? module.management_subscription["this"].subscription : null
}

output "connectivity_subscription" {
  description = "Subscription details including tags and metadata"
  value       = var.ecp_connectivity_subscription_id != "00000000-0000-0000-0000-000000000000" ? module.connectivity_subscription["this"].subscription : null
}

output "identity_subscription" {
  description = "Subscription details including tags and metadata"
  value       = var.ecp_identity_subscription_id != "00000000-0000-0000-0000-000000000000" ? module.identity_subscription["this"].subscription : null
}

output "security_subscription" {
  description = "Subscription details including tags and metadata"
  value       = var.ecp_security_subscription_id != "00000000-0000-0000-0000-000000000000" ? module.security_subscription["this"].subscription : null
}
