output "resource_group_id" {
  value       = azapi_resource.resource_group.id
  description = "The ID of the resource group."
}



# output "virtual_network_subnets" {
#   value = {
#     for key, val in azurerm_subnet.mgm : val.name => {
#       id                   = val.id,
#       name                 = val.name,
#       virtual_network_name = val.virtual_network_name
#       resource_group_name  = val.resource_group_name
#       address_prefixes     = val.address_prefixes
#     }
#   }
# }

# # output "key_vault" {
# #   value = try(length(azurerm_key_vault.mgm["this"].id), 0) == 0 ? null : {
# #     id             = azurerm_key_vault.mgm["this"].id
# #     name           = azurerm_key_vault.mgm["this"].name
# #     resource_group = azurerm_key_vault.mgm["this"].resource_group_name
# #     location       = azurerm_key_vault.mgm["this"].location
# #   }
# # }

# output "key_vault" {
#   value = try(length(azapi_resource.mgm_vault["this"].id), 0) == 0 ? null : {
#     id             = azapi_resource.mgm_vault["this"].id
#     name           = azapi_resource.mgm_vault["this"].name
#     resource_group = azurerm_resource_group.mgm.name
#     location       = azapi_resource.mgm_vault["this"].location
#   }
# }
