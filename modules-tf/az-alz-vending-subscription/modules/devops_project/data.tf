# NOTE: If running via Service Principal, that identity needs to be a member of 'Enterprise Service Accounts'
#     built in DevOps organizational level group
#     otherwise the adding of Entra ID based groups and accounts might fail

##################################################    Enterprise Service Accounts    ##################################################
data "azuread_client_config" "current" {}

data "azuredevops_client_config" "current" {}

data "azapi_client_config" "current" {}

data "azuread_directory_object" "current" {
  object_id = data.azuread_client_config.current.object_id
}

data "azuredevops_group" "enterprise_service_accounts" {
  project_id = null #  If project_id is not specified the project collection groups will be searched.
  name       = "Enterprise Service Accounts"
}

data "azuredevops_group_membership" "enterprise_service_accounts" {
  group_descriptor = data.azuredevops_group.enterprise_service_accounts.descriptor
}

data "azuread_service_principal" "master_spi" {
  client_id = var.vending_managed_identity_client_id
}

data "azuredevops_service_principal" "master_spi" {
  display_name = data.azuread_service_principal.master_spi.display_name
}