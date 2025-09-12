data "azapi_client_config" "this" {
}

# data "azapi_resource_id" "resource_group" {
#   type      = "Microsoft.Resources/resourceGroups@2021-04-01"
#   parent_id = data.azapi_client_config.this.subscription_resource_id
#   name      = var.resource_group_id
# }
data "azapi_resource" "resource_group" {
  type        = "Microsoft.Resources/resourceGroups@2021-04-01"
  resource_id = var.resource_group_id

  response_export_values = ["*"]
}
