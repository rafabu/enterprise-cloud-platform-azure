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

output "virtual_network_subnet" {
  description = "core properties of virtual networks subnet"
  value = {
    id                   = azurerm_subnet.devbox[var.subnet_artefact_names[0]].id,
    name                 = azurerm_subnet.devbox[var.subnet_artefact_names[0]].name,
    virtual_network_name = azurerm_subnet.devbox[var.subnet_artefact_names[0]].virtual_network_name,
    resource_group_name  = azurerm_subnet.devbox[var.subnet_artefact_names[0]].resource_group_name,
    address_prefixes     = azurerm_subnet.devbox[var.subnet_artefact_names[0]].address_prefixes
  }
}
