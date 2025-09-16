locals {
  # non-standard subscription providers that need to be registered
  #     use azapi to allow opportunistic registration
  ado_pool_resource_providers = [
    "Microsoft.DevOpsInfrastructure"
  ]
}

# register provider may be a slow operation
#     Assist terraform by actively assure it is registered and
#     add a sleep. Otherwise resource operations will fail initially.
#     Use only data-sources to not block enrolment should
#     registration already have happened.
data "azapi_resource" "provider_registration" {
  for_each = toset(local.ado_pool_resource_providers)

  type        = format("%s@2025-04-01", each.key)
  resource_id = "${data.azapi_client_config.this.subscription_resource_id}/providers/${each.key}"

  response_export_values = [
    "namespace",
    "registrationPolicy",
    "registrationState"
  ]
}

data "azapi_resource_action" "provider_registration" {
  for_each = toset(local.ado_pool_resource_providers)

  type        = format("%s@2025-04-01", each.key)
  resource_id = "${data.azapi_client_config.this.subscription_resource_id}/providers/${each.key}"

  # only register if it is currently unregistered (empty action does nothing but a get)
  action = contains(["NotRegistered", "Unregistered"], data.azapi_resource.provider_registration[each.key].output.registrationState) ? "Register" : ""
  method = contains(["NotRegistered", "Unregistered"], data.azapi_resource.provider_registration[each.key].output.registrationState) ? "POST" : "GET"

  response_export_values = [
    "namespace",
    "registrationPolicy",
    "registrationState"
  ]
}

resource "time_sleep" "wait_after_provider_register" {
  for_each = toset(local.ado_pool_resource_providers)

  # 5 mins sleep timer to allow slow provider registration to finish
  create_duration = data.azapi_resource.provider_registration[each.key].output.registrationState != "Registered" ? "5m" : "1ms"

  triggers = {
    create_duration = data.azapi_resource.provider_registration[each.key].output.registrationState != "Registered" ? "5m" : "1ms"
  }
}

data "azapi_resource" "provider_registration_recheck" {
  for_each = toset(local.ado_pool_resource_providers)

  type        = format("%s@2025-04-01", each.key)
  resource_id = "${data.azapi_client_config.this.subscription_resource_id}/providers/${each.key}"

  response_export_values = [
    "namespace",
    "registrationPolicy",
    "registrationState"
  ]

  lifecycle {
    postcondition {
      condition     = self.output.registrationState == "Registered"
      error_message = format("ERROR: Subscription provider '%s' is currently in state '%s'. Cannot provision any resources until it has been successfully registered.", self.output.namespace, self.output.registrationState)
    }
  }

  depends_on = [
    time_sleep.wait_after_provider_register
  ]
}
