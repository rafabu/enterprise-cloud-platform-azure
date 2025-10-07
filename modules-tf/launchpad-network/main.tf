# mock output-safe resource group info retrieval
#      to allow plan to complete without actual resource group
data "azapi_resource_action" "resource_groups" {
  type        = "Microsoft.ResourceGraph@2024-04-01"
  resource_id = "/providers/Microsoft.ResourceGraph"
  action      = "resources"
  body = {
    query = "resourceContainers | where id =~ '${var.resource_group_id}'"
    options = {
      resultFormat = "objectArray"
    }
  }
  response_export_values = [
    "count",
    "data"
  ]
}

locals {
  resource_group = try([
    for rg in data.azapi_resource_action.resource_groups.output.data : {
      name     = rg.name
      location = rg.location
    } if rg.id == var.resource_group_id][0], {
    name     = "mock-rg"
    location = "westeurope"
  })
}
