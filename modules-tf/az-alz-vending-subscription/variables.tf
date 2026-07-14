variable "azure_location" {
  type        = string
  description = "Default region for resources deployed into this subscription."
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

variable "ecp_azure_deployment_service_principal_client_id" {
  type        = string
  description = "Client ID of the Azure deployment service principal."
}

variable "ecp_azure_deployment_service_principal_object_id" {
  type        = string
  description = "Object ID of the Azure deployment service principal."
}

variable "ecp_parent_management_group_id" {
  type        = string
  description = "The management group ID of the root parent management group for the ECP environment"
}

variable "ecp_parent_management_group_name" {
  type        = string
  description = "The management group name of the root parent management group for the ECP environment"
}

variable "ecp_management_subscription_id" {
  type        = string
  description = "The identifier of the Azure Subscription. (e.g '00000000-0000-0000-0000-000000000000')"
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.ecp_management_subscription_id))
    error_message = "The subscription ID must be a valid GUID in the format '00000000-0000-0000-0000-000000000000'."
  }
}

variable "ecp_connectivity_subscription_id" {
  type        = string
  description = "The identifier of the Azure Subscription. (e.g '00000000-0000-0000-0000-000000000000')"
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.ecp_connectivity_subscription_id))
    error_message = "The subscription ID must be a valid GUID in the format '00000000-0000-0000-0000-000000000000'."
  }
}

variable "ecp_azure_devops_organization_name" {
  type        = string
  description = "name of Azure DevOps organization"
}

variable "ecp_azure_devops_project_name" {
  type        = string
  description = "Name of Azure DevOps project for ECP Platform"
}

variable "ecp_azure_devops_repository_name" {
  type        = string
  description = "Name of Azure DevOps repository for ECP"
}

variable "ecp_azure_devops_managed_devops_pool_name" {
  type        = string
  description = "name of Azure DevOps managed agent pool"
}

variable "subscription_id" {
  type        = string
  default     = null
  description = <<DESCRIPTION
An existing subscription id.

Use this when you do not want the module to create a new subscription.
But do want to manage the management group membership.

A GUID should be supplied in the format xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.
All letters must be lowercase.

When using this, `subscription_management_group_association_enabled` should be enabled,
and `subscription_management_group_id` should be supplied.

You may also supply an empty string if you want to create a new subscription alias.
In this scenario, `subscription_alias_enabled` should be set to `true` and the following other variables must be supplied:

- `subscription_alias_name`
- `subscription_alias_display_name`
- `subscription_alias_billing_scope`
- `subscription_alias_workload`
DESCRIPTION
}

variable "subscription_management_group_id" {
  type        = string
  default     = null
  description = <<DESCRIPTION
  The destination management group ID for the new subscription.

**Note:** Do not supply the display name.
The management group ID forms part of the Azure resource ID. E.g.,
`/providers/Microsoft.Management/managementGroups/{managementGroupId}`.
DESCRIPTION
}

variable "private_dns_zone_resource_ids" {
  type        = list(string)
  default     = ["/subscriptions/54a47b01-be16-4ac5-9c2c-a9847076d794/resourceGroups/iaih-d9-rg-ecpa-con-privatelink-dnszones/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"]
  description = "List of resource IDs for Private DNS Zones to link to the virtual networks."
}

variable "azure_devops_project_creation_enabled" {
  type        = bool
  description = "Whether to create the Azure DevOps project."
  default     = true
}

variable "azure_devops_project_name" {
  type        = string
  description = "The name of the Azure DevOps project"
  default     = null
}

variable "azure_devops_project_description" {
  type        = string
  description = "The description of the Azure DevOps project"
  default     = null
}

variable "vnet_address_space" {
  type        = list(string)
  description = "The address space for the workload VNet"
  default     = []
}

variable "subnet_configuration" {
  type = list(
    object({
      name             = string
      address_prefixes = list(string)

      private_endpoint_network_policies             = optional(string, "Disabled") # Disabled: no specific behaviour regarding NSG and UDR for private endpoints in this subnet
      private_link_service_network_policies_enabled = optional(bool, true)         # true: cannot deploy private link services to subnet(s) by default

      default_outbound_access_enabled = optional(bool, false)

      private_endpoint_allocate = optional(bool, false) # use this subnet to create private endpoints in

      delegations       = optional(list(string), [])
      service_endpoints = optional(list(string), null)
    })
  )
  default     = []
  description = "The subnet configuration for the workload VNet"
}

variable "resource_network_communication_mode" {
  type        = string
  description = "Configures PaaS resource network access mode. PrivateLink, Public or ServiceEndpoint. Defaults to PrivateLink."
  validation {
    condition = contains([
      "PrivateLink",
      "Public",
      "ServiceEndpoint"
    ], var.resource_network_communication_mode)
    error_message = "resource_network_communication_mode must be one of PrivateLink, Public or ServiceEndpoint."
  }
}

variable "bastion_connect_enabled" {
  type        = bool
  description = "Whether to connect to the bastion host"
  default     = false
}

variable "bastion_vnet_id" {
  type        = string
  description = "The ID of the bastion vnet"
  nullable    = true
  default     = null
}

variable "bastion_resource_id" {
  type        = string
  description = "The ID of the bastion host"
  nullable    = true
  default     = null
}


variable "vwan_connect_enabled" {
  type        = bool
  description = "Whether to connect to the vWAN"
  default     = true
}

variable "vwan_hub_resource_id" {
  type        = string
  description = "The ID of the vWAN hub"
  default     = null
}

variable "storage_account_creation_enabled" {
  type        = bool
  description = "Whether to create a storage account (for terraform backend use)"
  default     = true
}

variable "storage_account_network_rules" {
  type = object({
    bypass                     = optional(set(string), ["AzureServices"])
    default_action             = optional(string, "Deny")
    ip_rules                   = optional(set(string), [])
    virtual_network_subnet_ids = optional(set(string), [])
    private_link_access = optional(list(object({
      endpoint_resource_id = string
      endpoint_tenant_id   = optional(string)
    })))
  })
  default     = {}
  description = "Overrides for storage account network rules"
}

variable "nat_gateway_connection_enabled" {
  type        = bool
  description = "Whether to connect the workload VNet to a pre-existing NAT Gateway"
  default     = false
}

variable "nat_gateway_resource_id" {
  type        = string
  description = "The ID of the NAT Gateway to connect to"
  default     = null
}

variable "nat_gateway_creation_enabled" {
  type        = bool
  description = "Whether to create a NAT Gateway."
  default     = false
}

variable "nat_gateway_public_ip_count" {
  type        = number
  description = "The number of public IPs for the NAT gateway"
  default     = 1
  validation {
    condition     = var.nat_gateway_public_ip_count >= 1 && var.nat_gateway_public_ip_count <= 3
    error_message = "Availability zone must be between 1 and 3"
  }
}

// Permission Parameters
variable "workload_owners_group_member_object_ids" {
  type        = list(string)
  default     = []
  description = "List of workload owners"
}

variable "workload_owners_group_owners_object_ids" {
  type        = list(string)
  default     = []
  description = "List of workload owners who are also owners of the group"
}

variable "workload_owners_group_use_pim" {
  type        = bool
  description = "Whether to use PIM for workload owners group"
  default     = false
}

variable "workload_users_group_member_object_ids" {
  type        = list(string)
  default     = []
  description = "List of workload users"
}

variable "workload_users_group_owners_object_ids" {
  type        = list(string)
  description = "List of workload users"
}

variable "workload_users_group_use_pim" {
  type        = bool
  description = "Whether to use PIM for workload users"
  default     = false
}

variable "additional_entra_id_group_members" {
  type = map(object({
    group_object_id = string
    role_group_keys = list(string)
  }))
  default     = {}
  description = "Additional members to add to the Entra ID groups. The key is the group name and the value is a list of object IDs."
}


