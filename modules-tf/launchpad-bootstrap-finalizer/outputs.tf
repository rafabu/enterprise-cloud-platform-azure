output "launchpad_infrastructure" {
  description = "Summary information on the deployed launchpad infrastructure for ECP automation."
  value = {
    ado_agent_pool = length(var.launchpad_ado_managed_pool) > 0 ? {
      id                  = try(var.launchpad_ado_managed_pool["id"], null)
      name                = try(var.launchpad_ado_managed_pool["name"], null)
      resource_group_name = try(var.launchpad_ado_managed_pool["resource_group_name"], null)
      location            = try(var.launchpad_ado_managed_pool["location"], null)
    } : null
    launchpad_subscription = {
      id   = data.azurerm_client_config.this.subscription_id
      name = data.azurerm_subscription.this.display_name
    }
  }
}
