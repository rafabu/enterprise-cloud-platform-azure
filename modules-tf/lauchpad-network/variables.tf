variable "azure_location" {
  type = string
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
