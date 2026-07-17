resource "azapi_resource" "resource_group" {
  type      = "Microsoft.Resources/resourceGroups@2025-04-01"
  name      = "${data.azurecaf_name.rg.result}-bastion"
  parent_id = "/subscriptions/${var.ecp_connectivity_subscription_id}"
  location  = var.azure_location

  body = {
    properties = {}
  }

  tags = var.azure_tags

  response_export_values = [
    "id",
    "name",
    "location",
  ]

   lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
