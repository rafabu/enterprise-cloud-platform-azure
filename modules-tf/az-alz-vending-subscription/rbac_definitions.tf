data "azapi_resource_list" "parent_management_group_role_definitions" {
  type                   = "Microsoft.Authorization/roleDefinitions@2022-04-01"
  parent_id              = var.ecp_parent_management_group_id
  response_export_values = ["*"]

  depends_on = []
}

locals {
  custom_role_definitions = {
    for key, val in data.azapi_resource_list.parent_management_group_role_definitions.output.value : val.id => {
      name        = val.name
      id          = val.id
      role_name   = val.properties["roleName"]
      description = val.properties["description"]
      type        = val.properties["type"]
    }
    if val.properties["type"] == "CustomRole"
  }
  # IDs (name) of ALZ custom role definitions (see 'role_definition' artefacts
  custom_role_definition_application_owners = [
    for rd in local.custom_role_definitions : rd
    if rd.role_name == "Application-Owners (${var.ecp_parent_management_group_name})"
  ][0]
  custom_role_definition_network_management = [
    for rd in local.custom_role_definitions : rd
    if rd.role_name == "Network-Management (${var.ecp_parent_management_group_name})"
  ][0]
  custom_role_definition_network_subnet_contributor = [
    for rd in local.custom_role_definitions : rd
    if rd.role_name == "Network-Subnet-Contributor (${var.ecp_parent_management_group_name})"
  ][0]
  custom_role_definition_network_security_operations = [
    for rd in local.custom_role_definitions : rd
    if rd.role_name == "Security-Operations (${var.ecp_parent_management_group_name})"
  ][0]
  custom_role_definition_subscription_owner = [
    for rd in local.custom_role_definitions : rd
    if rd.role_name == "Subscription-Owner-Role-Restricted (${var.ecp_parent_management_group_name})"
  ][0]
  custom_role_definition_privatednszone_record_contributor = [
    for rd in local.custom_role_definitions : rd
    if rd.role_name == "Private-DNS-Zone-Record-Contributor (${var.ecp_parent_management_group_name})"
  ][0]

  subscription_owner_excluded_assignment_role_ids = [
    local.custom_role_definition_application_owners.name,
    local.custom_role_definition_network_management.name,
    local.custom_role_definition_subscription_owner.name,
    "76cc9ee4-d5d3-4a45-a930-26add3d73475", # Access Review Operator Service Role
    "92b92042-07d9-4307-87f7-36a593fc5850", # Azure File Sync Administrator
    "7b7c71ed-33fa-4ed2-a91a-e56d5da260b5", # Azure IoT Operations Onboarding
    "c914561b-1575-4601-af9c-a1356bf59818", # Azure Resilience Management Drills Administrator
    "b24988ac-6180-42a0-ab88-20f7382dd24c", # Contributor
    "4d97b98b-1d4f-4787-a291-c67834d212e7", # Network Contributor
    "8e3af657-a8ff-443c-a75c-2fe8c4bcb635", # Owner
    "a8889054-8d42-49c9-bc1c-52486c10e7cd", # Reservations Administrator
    "f58310d9-a9f6-439a-9e8d-f62e7b41a168", # Role Based Access Control Administrator
    "32e6a4ec-6095-4e37-b54b-12aa350ba81f", # Service Group Contributor
    "18d7d88d-d35e-4fb5-a5c3-7773c20a72d9"  # User Access Administrator
  ]
}
