locals {

  name_prefixes = join("-", try(var.azure_resource_name_elements.prefixes, []))

  name_template_role_assignable    = "ra-${local.name_prefixes}-${var.azure_resource_name_elements.name}-<role>"
  name_template_role_managed       = "rm-${local.name_prefixes}-${var.azure_resource_name_elements.name}-<role>"
  name_template_permission_managed = "pm-${local.name_prefixes}-${var.azure_resource_name_elements.name}-<permission>"
}
