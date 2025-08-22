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

  timeouts {
    create = "10m"
    delete = "10m"
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

  timeouts {
    create = "10m"
    delete = "10m"
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

# query for all namedLocation (to use them as reference in CA policies via display name or id)
data "msgraph_resource" "azuread_named_location" {
  url         = "identity/conditionalAccess/namedLocations"
  api_version = "v1.0"
  response_export_values = {
    # JMSPath query to extract id and displayName
    namedLocations = "value[].{id:id, displayName:displayName}"
  }

  depends_on = [
    azuread_named_location.ip_ranges,
    azuread_named_location.countries_and_regions
  ]
}

# ####################################################
# # Conditional Access Exclusion Group
# #
# #     Notes: use as a TEMPORARY workaround to exclude a group from all policies
# #
# ####################################################




# output "azuread_named_location" {
#   value = azuread_named_location.region_critical_high_risk
# }
