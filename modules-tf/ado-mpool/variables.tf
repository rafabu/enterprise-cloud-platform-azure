variable "ecp_network_main_ipv4_address_space" {
  type        = string
  description = "The main IPv4 address space for the ECP network"
}

variable "ecp_azure_devops_organization_name" {
  type        = string
  description = "name of Azure DevOps organization"
}

variable "ecp_azure_devops_project_name" {
  type        = string
  description = "name of Azure DevOps project for ECP"
}

variable "ecp_azure_root_parent_management_group_id" {
  type        = string
  description = "ID of parent management group under which the ECP hierarchy for the environment will be created. Recommended: One level below Azure's Root Management Group."
}

variable "ecp_configuration_repo" {
  type        = string
  description = "URL of the Git repository containing the ECP configuration for this environment."
}

variable "ecp_configuration_repo_version" {
  type        = string
  default     = "main"
  description = "Version (git tag) of the Git repository containing the ECP configuration for this environment."
}

variable "ecp_configuration_repo_deployment_root_path" {
  type        = string
  description = "subfolder path within the ecp_configuration_repo where the environment deployment files are located."
}

variable "azure_location" {
  type = string
}

variable "azure_resource_name_elements" {
  type = object({
    prefixes      = optional(list(string))
    suffixes      = optional(list(string))
    name          = optional(string)
    random_length = optional(number)
  })
  description = "Object containing naming components to be used by the azurecaf_name data source to generate resource names."
}

variable "azure_tags" {
  type    = map(string)
  default = {}
}

variable "virtual_network_id" {
  # e.g. output of launchpad-network module
  type        = string
  description = "Id of virtualNetwork"
}

variable "virtual_network_subnet_definitions" {
  type = map(object({
    artefactName          = string
    name                  = optional(string)
    addressPrefixes       = optional(list(string))
    defaultOutboundAccess = optional(bool)
    # delegations : optional(list(object({

    # })))
    virtualNetwork : object({
      artefactName = string
    })
    baseAddressOffsets = optional(list(object({
      netnum  = number
      newbits = number
    })))
    privateEndpointNetworkPolicies    = optional(string)
    privateLinkServiceNetworkPolicies = optional(string)
  }))
  description = "Map of virtual network artefacts (virtualNetwork), where the key is the artefactName and the value is an object containing properties of the virtual network."

  validation {
    condition = alltrue([
      for subnet in var.virtual_network_subnet_definitions :
      subnet.privateEndpointNetworkPolicies == null
      || contains([
        "Enabled",
        "NetworkSecurityGroupEnabled",
        "RouteTableEnabled",
        "Disabled"
      ], subnet.privateEndpointNetworkPolicies)
    ])
    error_message = "privateEndpointNetworkPolicies must be one of: Enabled, NetworkSecurityGroupEnabled, RouteTableEnabled, Disabled (or omitted)."
  }

  validation {
    condition = alltrue([
      for subnet in var.virtual_network_subnet_definitions :
      subnet.privateLinkServiceNetworkPolicies == null
      || contains([
        "Enabled",
        "Disabled"
      ], subnet.privateLinkServiceNetworkPolicies)
    ])
    error_message = "privateLinkServiceNetworkPolicies must be one of: Enabled, Disabled (or omitted)."
  }
}



variable "subnet_artefact_names" {
  type        = list(string)
  default     = []
  description = "List of virtualNetwork/subnet artefacts that are created"
}

variable "virtual_network_island_mode" {
  type        = bool
  default     = false
  description = "If true, indicates that the virtual network is in island mode (no outbound access by default); ADO managed pool will require a NAT gateway for outbound access if subnet integration is used."
}

variable "workload_identity_type" {
  type        = string
  default     = "userAssignedIdentity"
  description = "ADO pool identity type: userAssignedIdentity or serviceprincipal. Defaults to userAssignedIdentity."
  validation {
    condition     = contains(["serviceprincipal", "userAssignedIdentity"], var.workload_identity_type)
    error_message = "variable workload_identity_type must be either 'serviceprincipal' or 'userAssignedIdentity'."
  }
}

variable "dev_center_project_resource_id" {
  type        = string
  description = "(Required) The resource ID of the Dev Center project."
  nullable    = false
}

variable "backend_storage_accounts" {
  type = map(object({
    id       = string
    name     = string
    location = string
    private_endpoint_blob = optional(object({
      fqdn               = string
      private_ip_address = string
    }))
    ecp_level            = string
    tf_backend_container = string
    subscription_id      = string
    resource_group_name  = string
  }))
  description = "Map of storage accounts created for each ECP deployment level, with information required for private endpoint access without DNS"
}

variable "managed_devops_pool_maximum_concurrency" {
  type        = number
  default     = 2
  description = "(Optional) The maximum concurrency for the managed DevOps pool. Defaults to 2."
}

variable "managed_devops_pool_stateless_agent_profile" {
  type = object({
    manual_resource_predictions_profile = optional(object({
      time_zone          = string
      all_week_schedule  = optional(number)
      monday_schedule    = optional(map(number))
      tuesday_schedule   = optional(map(number))
      wednesday_schedule = optional(map(number))
      thursday_schedule  = optional(map(number))
      friday_schedule    = optional(map(number))
      saturday_schedule  = optional(map(number))
      sunday_schedule    = optional(map(number))
    }))
    automatic_resource_predictions_profile = optional(object({
      prediction_preference = string
    }))
  })
  description = "(Optional) The stateless agent profile for the managed DevOps pool."
  default     = {}
  # default = {
  #   manual_resource_predictions_profile = {
  #     time_zone = "W. Europe Standard Time"
  #     # all_week_schedule = 2
  #     monday_schedule = {
  #       "07:30:00" = 2,
  #       "21:00:00" = 0
  #     }
  #     tuesday_schedule = {
  #       "07:30:00" = 2,
  #       "21:00:00" = 0
  #     }
  #     wednesday_schedule = {
  #       "07:30:00" = 2,
  #       "21:00:00" = 0
  #     }
  #     thursday_schedule = {
  #       "07:30:00" = 2,
  #       "21:00:00" = 0
  #     }
  #     friday_schedule = {
  #       "07:30:00" = 2,
  #       "21:00:00" = 0
  #     }
  #     saturday_schedule = {}
  #     sunday_schedule   = {}
  #   }
  # }
}

variable "managed_devops_pool_vmss_fabric_profile" {
  type = object({
    sku_name = optional(string)
    image = optional(list(object({
      aliases               = list(string)
      buffer                = string
      well_known_image_name = string
    })))
    os_profile = optional(object({
      logon_type = string
    }))
    storage_profile = optional(object({
      os_disk_storage_account_type = string
      data_disk = optional(list(object({
        lun                  = number
        disk_size_gb         = number
        caching              = string
        storage_account_type = string
      })))
    }))
    }
  )
  description = "(Optional) The VMSS fabric profile for the managed DevOps pool."
  default     = {}
  # default = {
  #   sku_name = "Standard_D2as_v5"
  #   image = [
  #     {
  #       aliases               = ["ubuntu-24.04/latest"]
  #       buffer                = "*"
  #       well_known_image_name = "ubuntu-24.04/latest"
  #     }
  #   ]
  #   os_profile = {
  #     logon_type = "Service"
  #   }
  #   storage_profile = {
  #     os_disk_storage_account_type = "StandardSSD"
  #     data_disk                    = []
  #   }
  # }
}
