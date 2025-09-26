variable "ecp_network_main_ipv4_address_space" {
  type        = string
  description = "The main IPv4 address space for the ECP network"
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

variable "virtual_subnet_id" {
  # e.g. output of launchpad-network module
  type        = string
  description = "Id of virtualSubnet"
}

variable "storage_account_public_network_access_enabled" {
  type = bool
  description = "Whether to allow public network access for the storage account. Default is false."
  default = false
}