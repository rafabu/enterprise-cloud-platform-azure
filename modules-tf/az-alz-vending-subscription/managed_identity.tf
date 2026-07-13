moved {
  from = module.devops_project["this"].azapi_resource.project_uami
  to   = azapi_resource.uami
}

moved {
  from = module.devops_project["this"].azapi_resource.project_uami_lock
  to   = azapi_resource.uami_lock
}


resource "azapi_resource" "uami" {
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30"
  # UAMI does not (yet) exist in provider DS - just rename the RG one...
  name      = replace(data.azurecaf_name.rg.result, "-rg-", "-id-")
  parent_id = module.vending.resource_group_resource_ids["mgmt"]
  location  = var.azure_location

  tags = var.azure_tags

  response_export_values = [
    "properties.principalId",
    "properties.clientId"
  ]

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

# give Entra ID time to replicate the new UAMI before creating the service principal entitlement
resource "time_sleep" "uami_wait" {
  create_duration  = "60s"
  destroy_duration = "30s"

  depends_on = [
    azapi_resource.uami
  ]
}

resource "azapi_resource" "uami_lock" {
  type      = "Microsoft.Authorization/locks@2020-05-01"
  name      = "${azapi_resource.uami.name}-cannotdelete"
  parent_id = azapi_resource.uami.id

  body = {
    properties = {
      level = "CanNotDelete"
      notes = "Prevents accidental deletion of the DevOps project service connection identity"
    }
  }

  depends_on = [
    time_sleep.uami_wait
  ]
}
