locals {
  # non-standard subscription providers that need to be registered during "apply"
  #     use azapi to allow opportunistic registration
  subscription_resource_providers = [
    "Microsoft.Compute",
    "Microsoft.GuestConfiguration",
    "Microsoft.KeyVault",
    "Microsoft.ManagedIdentity",
    "Microsoft.Network",
    "Microsoft.OperationalInsights",
    "Microsoft.OperationsManagement",
    "Microsoft.PolicyInsights",
    "Microsoft.Quota",
    "Microsoft.Security",
    "Microsoft.Storage"
  ]
}

# register provider may be a slow operation
#     Assist terraform by actively assure it is registered and
#     add a sleep. Otherwise resource operations will fail initially.
#     Use only data-sources to not block enrolment should
#     registration already have happened.
data "azapi_resource" "provider_registration" {
  for_each = toset(local.subscription_resource_providers)

  type        = format("%s@2025-04-01", each.key)
  resource_id = "/subscriptions/${var.subscription_id}/providers/${each.key}"

  response_export_values = [
    "namespace",
    "registrationPolicy",
    "registrationState"
  ]
}

data "azapi_resource_action" "provider_registration" {
  for_each = toset(local.subscription_resource_providers)

  type        = format("%s@2025-04-01", each.key)
  resource_id = "/subscriptions/${var.subscription_id}/providers/${each.key}"

  # only register if it is currently unregistered (empty action does nothing but a get)
  action = contains(["NotRegistered", "Unregistered"], data.azapi_resource.provider_registration[each.key].output.registrationState) ? "Register" : ""
  method = contains(["NotRegistered", "Unregistered"], data.azapi_resource.provider_registration[each.key].output.registrationState) ? "POST" : "GET"

  response_export_values = [
    "namespace",
    "registrationPolicy",
    "registrationState"
  ]
}
