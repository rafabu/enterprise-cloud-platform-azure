##################################################    Variable Group    ##################################################
# serves as output for users of the workload subscription. Add whatever is important for their success.
resource "azuredevops_variable_group" "this_vending_output" {
  name         = var.variable_group_name
  description  = "Variable group for ${azuredevops_project.this.name} project. Get important information for your project automation from here. This variable group is automatically created by the ECP LZ Vending DevOps module."
  project_id   = azuredevops_project.this.id
  allow_access = true

  variable {
    name  = "entraIdRoleGroupIdOwner"
    value = var.owner_permission_group_object_id
  }
  variable {
    name  = "entraIdRoleGroupIdUser"
    value = var.user_permission_group_object_id
  }
  variable {
    name  = "azureSubscriptionId"
    value = local.uami_subscription_id
  }
  variable {
    name  = "azureSubscriptionName"
    value = local.uami_subscription_name
  }
  variable {
    name  = "devopsAgentPool"
    value = data.azuredevops_agent_pool.this.name
  }
  variable {
    name  = "devopsServiceEndpointName"
    value = azuredevops_serviceendpoint_azurerm.this.service_endpoint_name
  }
  #   variable {
  #     name  = "workloadManagementKeyVaultName"
  #     value = try(module.key_vault["this"].name, "")
  #   }
  #   variable {
  #     name  = "workloadManagementKeyVaultId"
  #     value = try(module.key_vault["this"].resource_id, "")
  #   }
  #   variable {
  #     name  = "workloadManagementResourceGroupName"
  #     value = module.resource_group_management.name
  #   }
  #   variable {
  #     name  = "workloadManagementResourceGrouId"
  #     value = module.resource_group_management.resource_id
  #   }

  # ECP Platform information
  variable {
    name  = "ecpManagementSubscriptionId"
    value = var.ecp_management_subscription_id
  }

  variable {
    name  = "ecpConnectivitySubscriptionId"
    value = var.ecp_connectivity_subscription_id
  }

  variable {
    name  = "ecpConnectivityPrivateDnsZoneResourceGroupName"
    value = basename(var.ecp_connectivity_private_dns_zone_resource_group_id)
  }

  variable {
    name  = "ecpIdentitySubscriptionId"
    value = var.ecp_identity_subscription_id
  }

  variable {
    name  = "ecpSecuritySubscriptionId"
    value = var.ecp_security_subscription_id
  }

  variable {
    name  = "workloadManagementStorageAccountName"
    value = var.storage_account_name
  }
  variable {
    name  = "workloadManagementStorageAccountId"
    value = var.storage_account_resource_id
  }
  #   variable {
  #     name  = "workloadManagementLogAnalyticsWorkspaceName"
  #     value = try(module.log_analytics_workspace["this"].resource.name, "")
  #   }
  #   variable {
  #     name  = "workloadManagementLogAnalyticsWorkspaceId"
  #     value = try(module.log_analytics_workspace["this"].resource_id, "")
  #   }
  #   variable {
  #     name  = "workloadManagementAppInsightsName"
  #     value = try(module.application_insights["this"].name, "")
  #   }
  #   variable {
  #     name  = "workloadManagementAppInsightsId"
  #     value = try(module.application_insights["this"].resource_id, "")
  #   }
  #   variable {
  #     name  = "workloadIdentifier"
  #     value = var.workload_identifier
  #   }
  #   variable {
  #     name  = "workloadNetworkResourceGroupName"
  #     value = module.resource_group_vnet.name
  #   }
  #   variable {
  #     name  = "workloadNetworkResourceGrouId"
  #     value = module.resource_group_vnet.resource_id
  #   }
  #   variable {
  #     name  = "workloadNetworkVnetName"
  #     value = module.vnet.name
  #   }
  #   variable {
  #     name  = "workloadNetworkVnetId"
  #     value = module.vnet.resource_id
  #   }
  #   variable {
  #     name  = "workloadNetworkSubnetNames"
  #     value = jsonencode([for key, attr in module.vnet.subnets : attr.name])
  #   }
  #   dynamic "variable" {
  #     for_each = module.vnet.subnets
  #     content {
  #       name  = "workloadNetworkSubnetAddressPrefixes-${variable.value.name}"
  #       value = jsonencode(variable.value.resource.body.properties.addressPrefixes)
  #     }
  #   }
  #   dynamic "variable" {
  #     for_each = module.vnet.subnets
  #     content {
  #       name  = "workloadNetworkSubnetId-${variable.value.name}"
  #       value = variable.value.resource_id
  #     }
  #   }
}

resource "azuredevops_pipeline_authorization" "this_vending_output" {
  project_id  = azuredevops_project.this.id
  resource_id = azuredevops_variable_group.this_vending_output.id
  type        = "variablegroup"
}
