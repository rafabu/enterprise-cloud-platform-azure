variable "vending_managed_identity_client_id" {
  type        = string
  description = "Client ID of the managed identity to create for the Azure DevOps project."
}

variable "azure_devops_project_creation_enabled" {
  type        = bool
  description = "Whether to create the Azure DevOps project."
  default     = true
}

variable "azure_devops_project_name" {
  type        = string
  description = "Name of the Azure DevOps project to create."
}

variable "azure_devops_project_description" {
  type        = string
  default     = ""
  description = "Description of the Azure DevOps project to create."
}

variable "managed_identity_resource_id" {
  type        = string
  description = "Resource ID of the managed identity to create for the Azure DevOps project."
}

variable "managed_identity_object_id" {
  type        = string
  description = "Object ID (Principal Id)of the managed identity to create for the Azure DevOps project."
}

variable "managed_identity_client_id" {
  type        = string
  description = "Client ID of the managed identity to create for the Azure DevOps project."
}

variable "owner_permission_group_object_id" {
  type        = string
  description = "Object ID of the Entra ID group that will be assigned the 'Owner' role on the Azure DevOps project."
}

variable "user_permission_group_object_id" {
  type        = string
  description = "Object ID of the Entra ID group that will be assigned the 'User' role on the Azure DevOps project."
}

variable "resource_group_id" {
  type        = string
  description = "Resource ID of the resource group to create the managed identity in."
}

variable "resource_group_location" {
  type        = string
  description = "Location of the resource group to create the managed identity in."
}

variable "resource_group_tags" {
  type        = map(string)
  description = "Tags applied to the resource group."
}

variable "shared_agent_pool_name" {
  type        = string
  description = "Name of the shared agent pool to assign to the Azure DevOps project."
}

variable "service_connection_name" {
  type        = string
  description = "Name of the service connection to create for the Azure DevOps project."
}

variable "variable_group_name" {
  type        = string
  description = "Name of the variable group to create for the Azure DevOps project."
}

variable "storage_account_name" {
  type        = string
  description = "Name of the storage account to create for the Azure DevOps project."
}

variable "storage_account_resource_id" {
  type        = string
  description = "Resource ID of the storage account to create for the Azure DevOps project."
}

variable "ecp_management_subscription_id" {
  type        = string
  description = "Subscription ID of the ECP Management subscription."
}

variable "ecp_connectivity_subscription_id" {
  type        = string
  description = "Subscription ID of the ECP Connectivity subscription."
}

variable "ecp_connectivity_private_dns_zone_resource_group_id" {
  type        = string
  description = "Resource group ID of the private DNS zone in the ECP Connectivity subscription."
}

variable "ecp_identity_subscription_id" {
  type        = string
  description = "Subscription ID of the ECP Identity subscription."
}

variable "ecp_security_subscription_id" {
  type        = string
  description = "Subscription ID of the ECP Security subscription."
}
