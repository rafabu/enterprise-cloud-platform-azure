data "azapi_client_config" "this" {
}

data "azapi_resource_id" "resource_group" {
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
  parent_id = data.azapi_client_config.this.subscription_resource_id
  name      = var.resource_group_name
}
