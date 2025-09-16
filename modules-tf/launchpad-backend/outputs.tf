output "resource_groups" {
  description = "Backend resource groups created for each ECP deployment level"
  value = {
    for key, val in azurerm_resource_group.lp : key => {
      id       = val.id
      name     = val.name
      location = val.location
    }
  }
}
