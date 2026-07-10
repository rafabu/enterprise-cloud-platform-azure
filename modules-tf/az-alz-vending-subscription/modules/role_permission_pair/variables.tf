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

variable "permission_display_name" {
  type        = string
  description = "Display name for the Entra ID group \"permission\"."
}

variable "use_pim" {
  type        = bool
  default     = false
  description = "Whether to use PIM for the Entra ID group \"role\"."
}

variable "pim_permanent_role_member_object_ids" {
 type        = list(string)
  default     = []
  description = "List of object IDs for members to be added to the Entra ID group \"role\" when PIM is used (use for workload identities)."
}
