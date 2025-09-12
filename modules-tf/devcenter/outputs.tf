output "dev_center" {
  value = {
    id                  = azapi_resource.dev_center.id
    name                = azapi_resource.dev_center.name
    location            = azapi_resource.dev_center.location
    resource_group_name = provider::azapi::parse_resource_id("Microsoft.DevCenter/devcenters", azapi_resource.dev_center.id).resource_group_name
  }
}

output "dev_center_project" {
  value = {
    id                  = azapi_resource.dev_center_project.id
    name                = azapi_resource.dev_center_project.name
    location            = azapi_resource.dev_center_project.location
    resource_group_name = provider::azapi::parse_resource_id("Microsoft.DevCenter/projects", azapi_resource.dev_center_project.id).resource_group_name
  }
}
