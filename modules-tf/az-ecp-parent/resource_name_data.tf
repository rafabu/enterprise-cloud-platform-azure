locals {

    name_prefixes = join ("-", try(var.azure_resource_name_elements.prefixes, []))

    name_template_role       = "ra-${local.name_prefixes}-${var.azure_resource_name_elements.name}-<role>"
    name_template_permission = "pm-${local.name_prefixes}-${var.azure_resource_name_elements.name}-<permission>"
}
