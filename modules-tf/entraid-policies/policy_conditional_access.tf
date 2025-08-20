locals {
  named_location_ip_definitions = {
    for key, val in var.named_location_definitions : key => val
    if val.ipRanges != null && length(val.ipRanges) > 0
  }
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


# resource "azuread_named_location" "ip_isolutions" {
#   display_name = "IPs: isolutions AG (Office Locations)"
#   ip {
#     ip_ranges = [
#       "212.98.37.52/32"
#     ]
#     trusted = true
#   }

#   timeouts {
#     create = "10m"
#     delete = "10m"
#   }

# }

# resource "azuread_named_location" "country_ch" {
#   display_name = "Country: CH (Switzerland)"
#   country {
#     countries_and_regions = [
#       "CH"
#     ]
#     country_lookup_method                 = "clientIpAddress"
#     include_unknown_countries_and_regions = false
#   }

#   timeouts {
#     create = "10m"
#     delete = "10m"
#   }
# }

# resource "azuread_named_location" "country_ch_geo" {
#   display_name = "Country: CH (Switzerland) - mfa gps coordinate fenced"
#   country {
#     countries_and_regions = [
#       "CH"
#     ]
#     country_lookup_method                 = "authenticatorAppGps"
#     include_unknown_countries_and_regions = false
#   }

#   timeouts {
#     create = "10m"
#     delete = "10m"
#   }
# }


# resource "azuread_named_location" "region_eu" {
#   display_name = "Region: EU"
#   country {
#     countries_and_regions = [
#       # "EU"
#       "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE"
#     ]
#     country_lookup_method                 = "clientIpAddress"
#     include_unknown_countries_and_regions = false
#   }

#   timeouts {
#     create = "10m"
#     delete = "10m"
#   }
# }

# resource "azuread_named_location" "region_eea" {
#   # https://ec.europa.eu/eurostat/statistics-explained/index.php?title=Glossary:European_Economic_Area_(EEA)
#   display_name = "Region: EEA (EU + IS, LI, NO)"
#   country {
#     countries_and_regions = [
#       # "EU"
#       "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE",
#       # "EEA"
#       "IS", "LI", "NO",
#     ]
#     country_lookup_method                 = "clientIpAddress"
#     include_unknown_countries_and_regions = false
#   }

#   timeouts {
#     create = "10m"
#     delete = "10m"
#   }

# }

# resource "azuread_named_location" "region_eu_adequacy" {
#   # https://commission.europa.eu/law/law-topic/data-protection/international-dimension-data-protection/adequacy-decisions_en
#   display_name = "Region: EU Adequacy (EU + EU approved adequately protected countries - GB)"
#   country {
#     countries_and_regions = [
#       # "EU"
#       "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE",
#       # Adequacy
#       "AD", "AR", "FO", "GG", "IL", "IM", "JP", "JE", "NZ", "KR", "CH", "UY"
#     ]
#     country_lookup_method                 = "clientIpAddress"
#     include_unknown_countries_and_regions = false
#   }

#   timeouts {
#     create = "10m"
#     delete = "10m"
#   }
# }


# resource "azuread_named_location" "region_critical_high_risk" {
#   display_name = "Region: Critical - high risk"
#   country {
#     countries_and_regions = [
#       # CN — China (incl. Hong Kong HK and Macao MO)
#       # RU — Russia
#       # IR — Iran
#       # KP — North Korea
#       # CU — Cuba
#       # VE — Venezuela
#       # BY — Belarus
#       # MM — Myanmar
#       # SY — Syria
#       # TM — Turkmenistan
#       # ER — Eritrea
#       "CN", "HK", "MO", "RU", "IR", "KP", "CU", "VE", "BY", "MM", "SY", "TM", "ER", "SD"
#     ]
#     country_lookup_method                 = "clientIpAddress"
#     include_unknown_countries_and_regions = false
#   }

#   timeouts {
#     create = "10m"
#     delete = "10m"
#   }
# }

# resource "azuread_named_location" "region_critical_medium_risk" {
#   display_name = "Region: Critical - medium risk"
#   country {
#     countries_and_regions = [
#       # TR — Türkiye
#       # AE — United Arab Emirates
#       # SA — Saudi Arabia
#       # EG — Egypt
#       # IQ — Iraq
#       # JO — Jordan
#       # PK — Pakistan
#       # VN — Vietnam
#       # KZ — Kazakhstan
#       # AZ — Azerbaijan
#       # ET — Ethiopia
#       # NG — Nigeria
#       "TR", "AE", "SA", "EG", "IQ", "JO", "PK", "VN", "KZ", "AZ", "ET", "NG"
#     ]
#     country_lookup_method                 = "clientIpAddress"
#     include_unknown_countries_and_regions = false
#   }

#   timeouts {
#     create = "10m"
#     delete = "10m"
#   }
# }

# resource "azuread_named_location" "region_critical_elevated_risk" {
#   display_name = "Region: Critical - elevated risk"
#   country {
#     countries_and_regions = [
#       # KI — Kiribati
#       # SB — Solomon Islands
#       # TV — Tuvalu
#       # TO — Tonga
#       # WS — Samoa
#       # VU — Vanuatu
#       # FJ — Fiji
#       # FM — Micronesia (Federated States of)
#       # MH — Marshall Islands
#       # PW — Palau
#       # NR — Nauru
#       # PG — Papua New Guinea
#       "KI", "SB", "TV", "TO", "WS", "VU", "FJ", "FM", "MH", "PW", "NR", "PG"
#     ]
#     country_lookup_method                 = "clientIpAddress"
#     include_unknown_countries_and_regions = false
#   }

#   timeouts {
#     create = "10m"
#     delete = "10m"
#   }
# }


# ####################################################
# # Conditional Access Policies
# #
# #     Notes: based both on:
# #       - M365 Admin Center: https://admin.microsoft.com/Adminportal/Home?ref=ConditionalAccessPolicies
# #       - Conditional Access as Code: https://github.com/AlexFilipin/ConditionalAccess
# #
# #
# #     Naming convention: follows
# #       https://learn.microsoft.com/en-us/entra/identity/conditional-access/plan-conditional-access#set-naming-standards-for-your-policies
# ####################################################

# resource "azuread_conditional_access_policy" "block_access_critical_regions" {
#   display_name = "290 - all - base protection - all apps: block access from critical regions"
#   state        = "enabled"

#   conditions {
#     applications {
#       included_applications = ["All"]
#       excluded_applications = []
#     }
#     client_app_types = ["all"]
#     locations {
#       # id of the named locations must be reduced to object_id (AzureAD provider 3.5)
#       #   https://github.com/hashicorp/terraform-provider-azuread/issues/1504
#       included_locations = [
#         element(split("/", azuread_named_location.region_critical_high_risk.id), 4),
#         element(split("/", azuread_named_location.region_critical_medium_risk.id), 4),
#         element(split("/", azuread_named_location.region_critical_elevated_risk.id), 4)
#       ]
#       excluded_locations = []
#     }
#     users {
#       included_users = ["All"]
#       excluded_users = [
#         "cfbfbbbb-21af-4b70-b9fe-04cf0a9130a6"
#       ]
#       excluded_groups = []
#     }
#   }
#   grant_controls {
#     operator          = "OR"
#     built_in_controls = ["block"]
#   }

#   timeouts {
#     create = "10m"
#     delete = "10m"
#   }
# }




# ####################################################
# # Conditional Access Exclusion Group
# #
# #     Notes: use as a TEMPORARY workaround to exclude a group from all policies
# #
# ####################################################




# output "azuread_named_location" {
#   value = azuread_named_location.region_critical_high_risk
# }

output "named_location_definitions" {
  value = var.named_location_definitions
}
