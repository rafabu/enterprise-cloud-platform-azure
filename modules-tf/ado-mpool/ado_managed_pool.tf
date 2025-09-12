# module "managed_devops_pool" {
#   source = "Azure/avm-res-devopsinfrastructure-pool/azurerm"

#   # managed devops pool does not (yet) exist in provider DS - just rename the RG one...
#   name                = replace(data.azurecaf_name.rg.result, "-rg-", "-mpool-")
#   resource_group_name = data.azapi_resource.resource_group.name
#   location            = data.azapi_resource.resource_group.location

#   dev_center_project_resource_id           = var.dev_center_project_resource_id
#   version_control_system_organization_name = var.ecp_azure_devops_organization_name
#   version_control_system_project_names = [
#     var.ecp_azure_devops_project_name
#   ]
#   version_control_system_type = "azuredevops"
#   # subnet_id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-resource-group/providers/Microsoft.Network/virtualNetworks/my-vnet/subnets/my-subnet"
# }
