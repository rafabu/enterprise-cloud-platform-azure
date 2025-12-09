
# re-use the pre-created ECP parent management group
#     note: id must match ecp-deployment-${deployment-code}
import {
  to = module.alz.azapi_resource.management_groups_level_0["ecp-deployment-rabu-d7"]  # Must be YOUR resource
  id = "${var.alz_parent_management_group_resource_id}"
}

module "alz" {
  source  = "Azure/avm-ptn-alz/azurerm"
  version = "0.15.0"

  architecture_name = var.ecp_alz_architecture_name
  location          = var.azure_location

  parent_resource_id = var.ecp_azure_root_parent_management_group_id

  subscription_placement = merge(
    # "management" mg is the ONLY one that is ALWAYS required 
    {
      management = {
        subscription_id       = var.ecp_management_subscription_id
        management_group_name = "ecp-deployment-${var.ecp_environment_name}-platform-management"
      }
    },
    var.ecp_launchpad_subscription_id != "00000000-0000-0000-0000-000000000000" ? {
      launchpad = {
        subscription_id       = var.ecp_launchpad_subscription_id
        management_group_name = "ecp-deployment-${var.ecp_environment_name}-platform-launchpad"
      }
    } : {},
    var.ecp_connectivity_subscription_id != "00000000-0000-0000-0000-000000000000" ? {
      connectivity = {
        subscription_id       = var.ecp_connectivity_subscription_id
        management_group_name = "ecp-deployment-${var.ecp_environment_name}-platform-connectivity"
      }
    } : {},
    var.ecp_identity_subscription_id != "00000000-0000-0000-0000-000000000000" ? {
      identity = {
        subscription_id       = var.ecp_identity_subscription_id
        management_group_name = "ecp-deployment-${var.ecp_environment_name}-platform-identity"
      }
    } : {},
    var.ecp_security_subscription_id != "00000000-0000-0000-0000-000000000000" ? {
      security = {
        subscription_id       = var.ecp_security_subscription_id
        management_group_name = "ecp-deployment-${var.ecp_environment_name}-platform-security"
      }
    } : {}
  )
#   management_group_hierarchy_settings = {
#     default_management_group_name            = "sandbox"
#     require_authorisation_for_group_creation = true
#     update_existing                          = true
#   }

  enable_telemetry                     = false
  role_assignment_name_use_random_uuid = true

  # acts as a depends_on workaround, specific to this AVM module
  dependencies = {
    #     policy_role_assignments = [
    #       module.dependency_example1.output,
    #       module.dependency_example2.output,
    #     ]
    #   }
  }
}
