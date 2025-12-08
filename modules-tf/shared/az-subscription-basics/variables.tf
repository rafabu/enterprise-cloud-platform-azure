variable "subscription_id" {
  type        = string
  description = "The identifier of the Azure Subscription. (e.g '00000000-0000-0000-0000-000000000000')"
  validation {
    condition     = length(var.subscription_id) == 0 || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "The subscription ID must be a valid GUID in the format '00000000-0000-0000-0000-000000000000'."
  }
}

variable "subscription_name" {
  type        = string
  default     = ""
  description = "The name of the Azure Subscription."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Base set of tags to apply to Azure resources in the subscription."
}

variable "read_only_tags" {
  type        = list(string)
  default     = []
  description = "Tag names which will be read-only and protected by policy(cannot be modified or deleted) after initial creation."
}