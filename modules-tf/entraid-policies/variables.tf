variable "named_location_definitions" {
  type = map(object({
    definitionName = string
    displayName    = string
    isTrusted      = optional(bool)
    countriesAndRegions = optional(list(string))
    includeUnknownCountriesAndRegions = optional(bool)
    countryLookupMethod = optional(string)
    ipRanges = optional(list(object({
      cidrAddress = string
    })))
  }))
  description = "Map of conditional access named location definitions, where the key is the reference of the definition and the value is an object containing properties of the named location policy."

# default = {
#     Country-CH = {
#       countriesAndRegions               = ["CH"]
#       countryLookupMethod               = "clientIpAddress"
#       definitionName                    = "Country-CH"
#       displayName                       = "Country: CH (Switzerland)"
#       includeUnknownCountriesAndRegions = false
#     }
#     Country-Critical-Elevated = {
#       countriesAndRegions               = ["KI", "SB", "TV", "TO", "WS", "VU", "FJ", "FM", "MH", "PW", "NR", "PG"]
#       countryLookupMethod               = "clientIpAddress"
#       definitionName                    = "Country-Critical-Elevated"
#       displayName                       = "Region: Critical - elevated risk"
#       includeUnknownCountriesAndRegions = false
#     }
#     Country-Critical-High = {
#       countriesAndRegions               = ["CN", "HK", "MO", "RU", "IR", "KP", "CU", "VE", "BY", "MM", "SY", "TM", "ER", "SD"]
#       countryLookupMethod               = "clientIpAddress"
#       definitionName                    = "Country-Critical-High"
#       displayName                       = "Region: Critical - high risk"
#       includeUnknownCountriesAndRegions = false
#     }
#     Country-Critical-Medium = {
#       countriesAndRegions               = ["TR", "AE", "SA", "EG", "IQ", "JO", "PK", "VN", "KZ", "AZ", "ET", "NG"]
#       countryLookupMethod               = "clientIpAddress"
#       definitionName                    = "Country-Critical-Medium"
#       displayName                       = "Region: Critical - medium risk"
#       includeUnknownCountriesAndRegions = false
#     }
#     IP-isolutions-office = {
#       definitionName = "IP-isolutions-office"
#       displayName    = "IPs: isolutions AG (Office Locations)"
#       ipRanges = [{
#         cidrAddress = "212.98.37.52/32"
#       }]
#       isTrusted = true
#     }
#     Region-EEA = {
#       countriesAndRegions               = ["AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE", "IS", "LI", "NO"]
#       countryLookupMethod               = "clientIpAddress"
#       definitionName                    = "Region-EEA"
#       displayName                       = "Region: EEA (EU + IS, LI, NO)"
#       includeUnknownCountriesAndRegions = false
#     }
#     Region-EU = {
#       countriesAndRegions               = ["AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE"]
#       countryLookupMethod               = "clientIpAddress"
#       definitionName                    = "Region-EU"
#       displayName                       = "Region: EU"
#       includeUnknownCountriesAndRegions = false
#     }
#     Region-EU-Adequacy = {
#       countriesAndRegions               = ["AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE", "AD", "AR", "FO", "GG", "IL", "IM", "JP", "JE", "NZ", "KR", "CH", "UY"]
#       countryLookupMethod               = "clientIpAddress"
#       definitionName                    = "Region-EU-Adequacy"
#       displayName                       = "Region: EU Adequacy (EU + EU approved adequately protected countries - GB)"
#       includeUnknownCountriesAndRegions = false
#     }
#   }

}
