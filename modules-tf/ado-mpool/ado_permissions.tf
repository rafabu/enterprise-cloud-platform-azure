# NOTE: If running via Service Principal, that identity needs to be a member of 'Enterprise Service Accounts'
#     built in DevOps organizational level group
#     otherwise the adding of Entra ID based groups and accounts might fail
data "azuredevops_group" "enterprise_service_accounts" {

  project_id = null #  If project_id is not specified the project collection groups will be searched.
  name       = "Enterprise Service Accounts"
}

data "azuredevops_group_membership" "enterprise_service_accounts" {

  group_descriptor = data.azuredevops_group.enterprise_service_accounts.descriptor
}

data "azuread_service_principal" "master_spi" {
  client_id = data.azurerm_client_config.this.client_id
}

data "azuredevops_service_principal" "master_spi" {
  
  display_name = data.azuread_service_principal.master_spi.display_name
}

resource "azuredevops_group_membership" "enterprise_service_accounts_l0_spi" {
  group = data.azuredevops_group.enterprise_service_accounts.descriptor
  members = [
    data.azuredevops_service_principal.master_spi.descriptor
  ]
  mode = "add"
}

output "azuredevops_group_membership" {
    value = data.azuredevops_group_membership.enterprise_service_accounts
}

output "azuredevops_service_principal" {
    value = data.azuredevops_service_principal.master_spi
}

output "azuredevops_client_config" {
  value = data.azuredevops_client_config.this
}