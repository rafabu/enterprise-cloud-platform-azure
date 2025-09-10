variable "ecp_azure_devops_organization_name" {
  type        = string
  description = "name of Azure DevOps organization"
}

variable "ecp_azure_devops_billing_subscription_id" {
  type        = optional(string)
  default     = null
  nullable    = true
  description = "Id of Azure subscription to link ADO Organization to for billing purposes."
}
