// ALZ (SLZ) Policy Assignments that need to be exempt on the staging VM resource groups
//     otherwise the VM builder will fail to deploy its resources (like storage account / key vault etc.)
//     any assignment of those policies affecting the scope need to be exempt.
locals {
  exemption_policy_name_list = [
    "Deny-PublicPaaSEndpoints"
  ]
}

data "azapi_resource_list" "exemption_policy_definitions" {
  type      = "Microsoft.Authorization/policyDefinitions@2026-06-01"
  parent_id = module.vending.subscription_resource_id

  # response_export_values = ["*"]

  response_export_values = {
    # policyDefinitions = "value[?contains(`${jsonencode(local.exemption_policy_name_list)}`, name)].{id: id, name: name, version: properties.version, policyType: properties.policyType}"
    policyDefinitions = "value[?contains(`${jsonencode(local.exemption_policy_name_list)}`, name)].{id: id, name: name, version: properties.version, policyType: properties.policyType}"
  }
}

data "azapi_resource_list" "exemption_policy_set_definitions" {
  type      = "Microsoft.Authorization/policySetDefinitions@2026-06-01"
  parent_id = module.vending.subscription_resource_id

  response_export_values = {
    policySetDefinitions = "value[?contains(`${jsonencode(local.exemption_policy_name_list)}`, name)].{id: id, name: name, version: properties.version, policyType: properties.policyType}"
  }
}

locals {
  policy_definitions = concat(
    data.azapi_resource_list.exemption_policy_set_definitions.output.policySetDefinitions,
    data.azapi_resource_list.exemption_policy_definitions.output.policyDefinitions
  )
}

data "azapi_resource_list" "exemption_policy_assignments" {
  type      = "Microsoft.Authorization/policyAssignments@2026-06-01"
  parent_id = module.vending.subscription_resource_id

  query_parameters = {
    "$filter" = ["atScope()"]
  }

  response_export_values = {
    policyAssignments = "value[?contains(`${jsonencode(local.policy_definitions[*].id)}`, properties.policyDefinitionId)].{id: id, name: name, enforcementMode: properties.enforcementMode, scope: properties.scope, policyDefinitionId: properties.policyDefinitionId}"
  }
}

### Waive "Deny-PublicPaaSEndpoints" if MS-Hosted DevOps pool is used --> allow public network access to storage account
resource "azapi_resource" "policy_exemptions_mgmt" {
  for_each = var.resource_network_communication_mode == "PrivateLink" && var.ecp_azure_devops_managed_devops_pool_name != "Azure Pipelines" ? {} : {
    for pair in flatten([
      for rg in ["mgmt"] : [
        for assignment in data.azapi_resource_list.exemption_policy_assignments.output.policyAssignments : {
          rg         = rg
          assignment = assignment
        }
      ]
    ]) : "${pair.rg}_${pair.assignment.name}" => pair
  }

  type = "Microsoft.Authorization/policyExemptions@2026-01-01-preview"
  body = {
    properties = {
      policyAssignmentId = each.value.assignment.id
      description        = "Waiving policy as DevOps Pool 'Azure Pipelines' is selected and requires public network access to storage account."
      displayName        = each.value.assignment.name
      exemptionCategory  = "Waiver"
    }
  }
  name      = substr(sha1(each.value.assignment.id), 0, 16)
  parent_id = module.vending.resource_group_resource_ids[each.value.rg]
}

resource "time_sleep" "policy_exemptions_mgmt_create_wait" {
  for_each = toset(var.resource_network_communication_mode == "PrivateLink" && var.ecp_azure_devops_managed_devops_pool_name != "Azure Pipelines" ? [] : ["sleep"])

  depends_on = [
    azapi_resource.policy_exemptions_mgmt
  ]

  create_duration = "60s"
}
