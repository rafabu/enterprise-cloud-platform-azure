locals {
  # ipNamedLocation
  named_location_ip_definitions = {
    for key, val in var.named_location_definitions : key => val
    if val.ipRanges != null && length(val.ipRanges) > 0
  }
  # countryNamedLocation
  named_location_country_definitions = {
    for key, val in var.named_location_definitions : key => val
    if val.countriesAndRegions != null && length(val.countriesAndRegions) > 0
  }
}

####################################################
# Named Locations
#     Notes:
#          ip_ranges: IPv4 CIDR or IPv6 format from IETF RFC596
#          countries_and_regions are ISO 3166-1 alpha-2 codes
#
#          1st time creation fails if done directly on an untouched tenant with provider 3.5
#          Workaround - use pre provisioner to create one, which initializes "something"
#               and then stuff works as expected
####################################################

resource "azuread_named_location" "ip_ranges" {
  for_each = local.named_location_ip_definitions

  display_name = each.value.displayName
  ip {
    ip_ranges = [for ip in each.value.ipRanges : ip.cidrAddress]
    trusted   = each.value.isTrusted != null ? each.value.isTrusted : false
  }

  provisioner "local-exec" {
    # delay operations randomly between 5 and 30 seconds to avoid "simultaneous" creation which the API dislikes
    when        = create
    interpreter = ["pwsh", "-NoLogo", "-NonInteractive", "-ExecutionPolicy", "RemoteSigned", "-command"]
    command     = <<-SCRIPT
      start-sleep -Seconds (Get-Random -Minimum 5 -Maximum 30)
    SCRIPT
  }

  timeouts {
    create = "10m"
    delete = "10m"
  }

  depends_on = [
    terraform_data.policy_identity_security_defaults_enforcement_update
  ]

  lifecycle {
    precondition {
      condition     = local.reference_directory_license_level != "AAD_FREE"
      error_message = "Conditional Access requires Entra ID Premium P1 or P2 license. However, the tenant is currently at license level: ${local.reference_directory_license_level}."
    }
  }
}

resource "azuread_named_location" "countries_and_regions" {
  for_each = local.named_location_country_definitions

  display_name = each.value.displayName
  country {
    countries_and_regions                 = each.value.countriesAndRegions
    country_lookup_method                 = each.value.countryLookupMethod != null ? each.value.countryLookupMethod : "clientIpAddress"
    include_unknown_countries_and_regions = each.value.includeUnknownCountriesAndRegions != null ? each.value.includeUnknownCountriesAndRegions : false
  }

  provisioner "local-exec" {
    # delay operations randomly between 5 and 30 seconds to avoid "simultaneous" creation which the API dislikes
    when        = create
    interpreter = ["pwsh", "-NoLogo", "-NonInteractive", "-ExecutionPolicy", "RemoteSigned", "-command"]
    command     = <<-SCRIPT
      start-sleep -Seconds (Get-Random -Minimum 5 -Maximum 30)
    SCRIPT
  }

  timeouts {
    create = "10m"
    delete = "10m"
  }

  depends_on = [
    terraform_data.policy_identity_security_defaults_enforcement_update,
    azuread_named_location.ip_ranges # API dislikes parallel creation of named locations
  ]

  lifecycle {
    precondition {
      condition     = local.reference_directory_license_level != "AAD_FREE"
      error_message = "Conditional Access requires Entra ID Premium P1 or P2 license. However, the tenant is currently at license level: ${local.reference_directory_license_level}."
    }
  }
}

locals {
  named_location_resources = merge(
    # id normalization required with azurerm provider 3.5
    {
      for key, val in azuread_named_location.ip_ranges : key => {
        display_name = val.display_name
        id           = split("/", val.id)[length(split("/", val.id)) - 1]
      }
    },
    {
      for key, val in azuread_named_location.countries_and_regions : key => {
        display_name = val.display_name
        id           = split("/", val.id)[length(split("/", val.id)) - 1]
      }
    }
  )
}

output "conditional_access_named_location" {
  value = { for key, val in merge(
    azuread_named_location.ip_ranges,
    azuread_named_location.countries_and_regions
    ) : key => {
    display_name = val.display_name
    id           = split("/", val.id)[length(split("/", val.id)) - 1]
    }
  }
}
