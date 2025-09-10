# register microsoft.visualstudio
#     Use only data-sources to not block enrolment should
#     registration already have happened.
data "azapi_resource" "microsoft_visualstudio" {
  type        = "Microsoft.Visualstudio@2014-02-26"
  resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Visualstudio"

  response_export_values = [
    "namespace",
    "registrationPolicy",
    "registrationState"
  ]
}

data "azapi_resource_action" "microsoft_visualstudio" {
  type        = "Microsoft.Visualstudio@2014-02-26"
  resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Visualstudio"

  # only register if it is currently unregistered (empty action does nothing but a get)
  action = contains(["NotRegistered", "Unregistered"], jsondecode(data.azapi_resource.microsoft_visualstudio.output).registrationState) ? "Register" : ""
  method = contains(["NotRegistered", "Unregistered"], jsondecode(data.azapi_resource.microsoft_visualstudio.output).registrationState) ? "POST" : "GET"

  response_export_values = [
    "namespace",
    "registrationPolicy",
    "registrationState"
  ]
}

resource "time_sleep" "wait_after_provider_register_microsoft_visualstudio" {
  # 2 mins sleep timer to allow provider registration to finish
  create_duration = jsondecode(data.azapi_resource_action.microsoft_visualstudio.output).registrationState == "Registering" ? "2m" : "1ms"

  triggers = {
    create_duration = jsondecode(data.azapi_resource_action.microsoft_visualstudio.output).registrationState == "Registering" ? "2m" : "1ms"
  }
}

data "azapi_resource" "microsoft_visualstudio_recheck" {
  type        = "Microsoft.Visualstudio@2014-02-26"
  resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Visualstudio"

  response_export_values = [
    "namespace",
    "registrationPolicy",
    "registrationState"
  ]

  lifecycle {
    postcondition {
      condition     = jsondecode(self.output).registrationState == "Registered"
      error_message = format("ERROR: Subscription provider '%s' is currently in state '%s'. Cannot provision any resources until it has been successfully registered.", jsondecode(self.output).namespace, jsondecode(self.output).registrationState)
    }
  }

  depends_on = [
    time_sleep.wait_after_provider_register_microsoft_visualstudio
  ]
}

