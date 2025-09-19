data "azapi_resource" "resource_group" {
  type        = "Microsoft.Resources/resourceGroups@2021-04-01"
  resource_id = var.resource_group_id

  response_export_values = ["*"]
}

