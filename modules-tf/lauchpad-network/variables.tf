variable "azure_location" {
  type = string
}

variable "azure_resource_name_elements" {
  type = object({
    prefixes = optional(list(string))
    suffixes = optional(list(string))
    name      = optional(string)
    random_length = optional(number)
  })
  description = "Object containing naming components to be used by the azurecaf_name data source to generate resource names."
}

variable "azure_tags" {
  type = map(string)
  default = {}
}

variable "virtual_network_address_space" {
  type        = string
  description = "The address space for the virtual network"
  default     = "10.0.0.0/24"
}
