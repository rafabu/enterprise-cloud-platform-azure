resource "azapi_resource" "ado_billing" {
  type      = "Microsoft.VisualStudio/accounts@2014-02-26" # "2014-04-01-preview"
  name      = var.ecp_azure_devops_organization_name
  parent_id = "/providers/Microsoft.VisualStudio"

  body = jsonencode({
    properties = {
      billingOwner = {
        id = "/subscriptions/${var.ecp_azure_devops_billing_subscription_id != null ? var.ecp_azure_devops_billing_subscription_id : data.azurerm_client_config.current.subscription_id}"
      }
    }
  })

  depends_on = [
    data.azapi_resource.microsoft_visualstudio_recheck
  ]
}
