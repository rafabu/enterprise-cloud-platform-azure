##################################################    Azure DevOps Project    ##################################################

resource "azuredevops_project" "this" {
  name               = var.azure_devops_project_name
  visibility         = "private"
  version_control    = "Git"
  work_item_template = "Agile"
  description        = var.azure_devops_project_description
  features = {
    boards       = "disabled"
    repositories = "enabled"
    pipelines    = "enabled"
    testplans    = "disabled"
    artifacts    = "disabled"
  }

  lifecycle {
    ignore_changes = [description]

    precondition {
      condition = data.azuread_directory_object.current.type != "ServicePrincipal" ? true : contains(
        data.azuredevops_group_membership.enterprise_service_accounts.members,
        data.azuredevops_service_principal.master_spi["this"].descriptor
      )
      error_message = "Service Principal/MSI ${try(data.azuread_service_principal.master_spi["this"].display_name, "")} must be a member of built-in organizational group 'Enterprise Service Accounts' in Azure DevOps organization."
    }
  }
}

data "azuredevops_group" "project_administrators" {
  project_id = azuredevops_project.this.id
  name       = "Project Administrators"
}

data "azuredevops_group" "project_readers" {
  project_id = azuredevops_project.this.id
  name       = "Readers"
}

##################################################    Project Administrators    ##################################################
#     contributors (Entra ID Group)
resource "azuredevops_group_entitlement" "lz_owners" {
  origin_id = var.owner_permission_group_object_id
  origin    = "aad"
}

resource "azuredevops_group_membership" "lz_owners_project_administrators" {
  group = data.azuredevops_group.project_administrators.descriptor
  members = [
    azuredevops_group_entitlement.lz_owners.descriptor
  ]
  mode = "add"
}

##################################################    Project Readers    ##################################################
#     user (Entra ID Group)
resource "azuredevops_group_entitlement" "lz_users" {
  origin_id = var.user_permission_group_object_id
  origin    = "aad"
}

resource "azuredevops_group_membership" "lz_users_project_readers" {
  group = data.azuredevops_group.project_readers.descriptor
  members = [
    azuredevops_group_entitlement.lz_users.descriptor
  ]
  mode = "add"
}
