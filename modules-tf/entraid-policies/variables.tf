variable "named_location_definitions" {
  # https://learn.microsoft.com/en-us/graph/api/resources/countrynamedlocation?view=graph-rest-1.0
  type = map(object({
    artefactName                      = string
    displayName                       = string
    isTrusted                         = optional(bool)
    countriesAndRegions               = optional(list(string))
    includeUnknownCountriesAndRegions = optional(bool)
    countryLookupMethod               = optional(string)
    ipRanges = optional(list(object({
      cidrAddress = string
    })))
    # MS-graph specific properties which are not used in the module but allow them for compatibility
    #     "@odata.type" must not be included!
    id               = optional(string)
    createdDateTime  = optional(string)
    modifiedDateTime = optional(string)
    deletedDateTime  = optional(string)
  }))
  description = "Map of conditional access named location definitions (countrynamedlocation), where the key is the artefactName and the value is an object containing properties of the named location policy."
}
