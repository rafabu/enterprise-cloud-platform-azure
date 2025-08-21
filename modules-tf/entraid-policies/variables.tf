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
      disableResilienceDefaults       = optional()
      applicationEnforcedRestrictions = optional()
      cloudAppSecurity                = optional()
      secureSignInSession             = optional()
      signInFrequency = optional(object({
        value               = optional(number)
        type                = optional(string)
        authenticationTypes = optional(list(string))
        frequencyInterval   = optional()
        isEnabled           = bool
      }))
      persistentBrowser = optional(object({
        isEnabled = bool
        mode      = optional(string)
      }))
    }))
    # conditionalAccessConditionSet
    conditions = object({
      applications               = optional()
      authenticationFlows        = optional()
      clientApplications         = optional()
      clientAppTypes             = optional()
      devices                    = optional()
      deviceStates               = optional()
      locations                  = optional()
      platforms                  = optional()
      servicePrincipalRiskLevels = optional()
      signInRiskLevels           = optional()
      userRiskLevels             = optional()
      users                      = optional()
      insiderRiskLevels          = optional()
      times                      = optional()
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
    partialEnablementStrategy = optional()
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


output "conditional_access_policy_definitions" {
  value = var.conditional_access_policy_definitions
}