variable "role_display_name" {
  type        = string
  description = "Display name for the Entra ID group \"role\"."
}

variable "role_eligible_display_name" {
  type        = string
  default     = ""
  description = "Display name for the Entra ID group \"PIM-able role\"."
}

variable "role_member_object_ids" {
  type        = list(string)
  description = "List of object IDs for members to be added to the Entra ID group \"role\"."
}

variable "role_owner_object_ids" {
  type        = list(string)
  description = "List of object IDs for owners to be added to the Entra ID group \"role\"."
}

variable "permission_display_name" {
  type        = string
  description = "Display name for the Entra ID group \"permission\"."
}

variable "use_pim" {
  type        = bool
  default     = false
  description = "Whether to use PIM for the Entra ID group \"role\"."
}

variable "permanent_permission_member_object_ids" {
 type        = list(string)
  default     = []
  description = "List of object IDs for members to be added to the Entra ID group \"permission\" - when PIM is used permanently to the \"privileged\" permission group (use for workload identities)."
}

variable "vending_managed_identity_object_id" {
  type        = string
  description = "Object ID of the managed identity used for vending."
}
