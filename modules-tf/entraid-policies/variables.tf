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

variable "conditional_access_policy_definitions" {
  # https://learn.microsoft.com/en-us/graph/api/resources/conditionalaccesspolicy?view=graph-rest-1.0
  type = map(object({
    artefactName = string
    displayName  = string
    state        = string
    # conditionalAccessSessionControls
    sessionControls = optional(object({
      disableResilienceDefaults       = optional(any)
      applicationEnforcedRestrictions = optional(any)
      cloudAppSecurity                = optional(any)
      secureSignInSession             = optional(any)
      signInFrequency = optional(object({
        value               = optional(number)
        type                = optional(string)
        authenticationTypes = optional(list(string))
        frequencyInterval   = optional(any)
        isEnabled           = bool
      }))
      persistentBrowser = optional(object({
        isEnabled = bool
        mode      = optional(string)
      }))
    }))
    # conditionalAccessConditionSet
    conditions = object({
      applications               = optional(any)
      authenticationFlows        = optional(any)
      clientApplications         = optional(any)
      clientAppTypes             = optional(any)
      devices                    = optional(any)
      deviceStates               = optional(any)
      locations                  = optional(any)
      platforms                  = optional(any)
      servicePrincipalRiskLevels = optional(any)
      signInRiskLevels           = optional(any)
      userRiskLevels             = optional(any)
      users                      = optional(any)
      insiderRiskLevels          = optional(any)
      times                      = optional(any)
    })
    # conditionalAccessGrantControls
    grantControls = optional(object({
      operator                    = optional(string)
      builtInControls             = optional(list(string))
      termsOfUse                  = optional(list(string))
      customAuthenticationFactors = optional(list(string))
      authenticationStrengths     = optional(string)
    }))
    templateId                = optional(string)
    partialEnablementStrategy = optional(any)
    # MS-graph specific properties which are not used in the module but allow them for compatibility
    #     "@odata.type" must not be included!
    id               = optional(string)
    createdDateTime  = optional(string)
    modifiedDateTime = optional(string)
    deletedDateTime  = optional(string)
  }))

  validation {
    condition = alltrue([
      for def in var.conditional_access_policy_definitions : contains(["enabled", "disabled", "enabledForReportingButNotEnforced"], def.state)
    ])
    error_message = "conditionalaccesspolicy 'state' must be 'enabled', 'disabled' or 'enabledForReportingButNotEnforced'."
  }
  description = "Map of conditional access policy definitions (conditionalAccessPolicy), where the key is the artefactName and the value is an object containing properties of the conditional access policy."

  
}
