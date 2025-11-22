locals {
  matchpattern_guid              = "(?i)^[{]?[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}[}]?$"
  matchpattern_ecp_artefact      = "(?i)^<ECP_ARTEFACT>:(.+)$"
  matchpattern_displayname       = "(?i)^<DISPLAYNAME>:(.+)$"
  matchpattern_mail              = "(?i)^<MAIL>:(.+)$"
  matchpattern_userprincipalname = "(?i)^<USERPRINCIPALNAME>:(.+)$"
}


locals {
  ecp_environment_name = var.azure_resource_name_elements.prefixes[0]
}