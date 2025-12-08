locals {
  read_only_tag_object = {
    for key, val in var.tags : key => val
    if contains(var.read_only_tags, key)
  }
}

# write tag values on subscription level
#     make remediation (changes to tag values) more efficient by applying each tag independently per subscription
resource "azapi_resource_action" "subscription_tags" {
  for_each = toset(length(var.tags) > 0 ? ["this"] : [])

  type        = "Microsoft.Resources/tags@2025-04-01"
  resource_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Resources/tags/default"
  method      = "PUT"
  body = {
    properties = {
      tags = {
        for name, value in var.tags : name => value
      }
    }
  }
  response_export_values = ["*"]

  depends_on = [
    # no parallel modification
    azapi_resource_action.subscription_name
  ]
}

# settle in policy after destroy policy assignment, before updating tag values on the subscription
resource "time_sleep" "subscription_tags_destroy_wait" {

  create_duration  = "15s"
  destroy_duration = "30s"

  lifecycle {
    replace_triggered_by = [
      azapi_resource_action.subscription_tags
    ]
  }
}

# assign built-in policy 'Add or replace a tag on subscriptions' (61a4d60b-7326-440e-8051-9f94394d4dd1)
#     for every tag value that is required. This sets the affected tag values to read-only.
#     policy is deployed at subscription level, not management group!
data "azapi_resource" "subscription_tag_modify_policy_definition" {
  type                   = "Microsoft.Authorization/policyDefinitions@2023-04-01"
  name                   = "61a4d60b-7326-440e-8051-9f94394d4dd1"
  parent_id              = "/"
  response_export_values = ["*"]
}

resource "azapi_resource" "subscription_tag_modify_policy_assignment" {
  for_each = local.read_only_tag_object

  type      = "Microsoft.Authorization/policyAssignments@2022-06-01"
  name      = "MDF_Sb_Tg_${each.key}"
  parent_id = "/subscriptions/${var.subscription_id}"

  body = {
    properties = {
      displayName        = "${data.azapi_resource.subscription_tag_modify_policy_definition.output.properties.displayName} - ${each.key}"
      description        = "${data.azapi_resource.subscription_tag_modify_policy_definition.output.properties.description} - tag '${each.key}': '${each.value}'"
      policyDefinitionId = data.azapi_resource.subscription_tag_modify_policy_definition.id
      enforcementMode    = "Default"
      parameters = {
        tagName = {
          value = each.key
        }
        tagValue = {
          value = each.value
        }
      }
      nonComplianceMessages = [
        {
          message = "Subscription tag '${each.key}' must have value '${each.value}'"
        }
      ]
    }
    identity = {
      type = "SystemAssigned"
    }
    location = var.region
  }

  response_export_values = ["*"]

  lifecycle {
    replace_triggered_by = [
      # if tags change, remove (to allow updating) and then re-apply
      azapi_resource_action.subscription_tags
    ]
  }

  depends_on = [
    time_sleep.subscription_tags_destroy_wait
  ]
}

resource "azapi_resource" "subscription_tag_modify_policy_role_assignment" {
  for_each = local.read_only_tag_object

  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = uuidv5("oid", "${var.subscription_id}-${each.key}-${plantimestamp()}")
  parent_id = azapi_resource.subscription_tag_modify_policy_assignment[each.key].parent_id
  body = {
    properties = {
      # role definition id needs to be normalized to avoid issues with casing
      roleDefinitionId = "/subscriptions/${var.subscription_id}${replace(data.azapi_resource.subscription_tag_modify_policy_definition.output.properties.policyRule.then.details.roleDefinitionIds[0], "microsoft.authorization/roleDefinitions", "Microsoft.Authorization/roleDefinitions")}"
      principalId      = azapi_resource.subscription_tag_modify_policy_assignment[each.key].output.identity.principalId
      principalType    = "ServicePrincipal"
    }
  }

  lifecycle {
    ignore_changes = [
      name
    ]
    replace_triggered_by = [
      # if tags change, remove (to allow updating) and then re-apply
      azapi_resource.subscription_tag_modify_policy_assignment[each.key]
    ]
  }
}

# settle in policy assignments after create before proceeding with any resource deployments on this subscription
resource "time_sleep" "subscription_tag_modify_policy_assignment_wait" {

  depends_on = [
    azapi_resource.subscription_tag_modify_policy_assignment
  ]

  create_duration  = "15s"
  destroy_duration = "0s"

  lifecycle {
    replace_triggered_by = [
      azapi_resource.subscription_tag_modify_policy_role_assignment
    ]
  }
}
