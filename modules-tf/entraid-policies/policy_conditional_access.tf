locals {
  # conditionalaccessPolicy
  # look for referencing artefacts and put in their IDs of types:
  #   - namedLocation
  conditional_access_policy_definitions = {
    for key, val in var.conditional_access_policy_definitions : key => {
      artefactName = val.artefactName
      displayName  = val.displayName
      state        = val.state
      conditions = merge(
        {
          for ck, cv in val.conditions : ck => cv
          if ck != "locations"
        },
        {
          locations = {
            includeLocations = distinct(concat(
              [
                # GUID of named location
                for iloc in try(val.conditions.locations.includeLocations, []) : iloc
                if length(regexall(local.matchpattern_guid, iloc)) > 0
              ],
              [
                # lookup ECP artefact (named location)
                for iloc in try(val.conditions.locations.includeLocations, []) : local.named_location_resources[regexall(local.matchpattern_ecp_artefact, iloc)[0][0]].id
                if length(regexall(local.matchpattern_ecp_artefact, iloc)) > 0
              ],
              [
                # lookup by displayName (named location)
                #     if displayName isn't found (yet), ignore it for now
                for iloc in try(val.conditions.locations.includeLocations, []) : [
                  for nLoc in data.msgraph_resource.azuread_named_location.output.namedLocations : nLoc.id
                  if nLoc.displayName == regexall(local.matchpattern_displayname, iloc)[0][0]
                ][0]
                if length(regexall(local.matchpattern_displayname, iloc)) > 0 &&
                length([
                  for nLoc in data.msgraph_resource.azuread_named_location.output.namedLocations : nLoc.id
                  if nLoc.displayName == regexall(local.matchpattern_displayname, iloc)[0][0]
                ]) > 0
              ]
            ))
            excludeLocations = distinct(concat(
              [
                # GUID of named location
                for iloc in try(val.conditions.locations.excludeLocations, []) : iloc
                if length(regexall(local.matchpattern_guid, iloc)) > 0
              ],
              [
                # lookup ECP artefact (named location)
                for iloc in try(val.conditions.locations.excludeLocations, []) : local.named_location_resources[regexall(local.matchpattern_ecp_artefact, iloc)[0][0]].id
                if length(regexall(local.matchpattern_ecp_artefact, iloc)) > 0
              ],
              [
                # lookup by displayName (named location)
                #     if displayName isn't found (yet), ignore it for now
                for iloc in try(val.conditions.locations.excludeLocations, []) : [
                  for nLoc in data.msgraph_resource.azuread_named_location.output.namedLocations : nLoc.id
                  if nLoc.displayName == regexall(local.matchpattern_displayname, iloc)[0][0]
                ][0]
                if length(regexall(local.matchpattern_displayname, iloc)) > 0 &&
                length([
                  for nLoc in data.msgraph_resource.azuread_named_location.output.namedLocations : nLoc.id
                  if nLoc.displayName == regexall(local.matchpattern_displayname, iloc)[0][0]
                ]) > 0
              ]
            ))
          }
        }
      )
      grantControls   = try(val.grantControls, null) != null ? val.grantControls : null
      sessionControls = try(val.sessionControls, null) != null ? val.sessionControls : null
    }
  }
}

output "pol_local" {
  value = local.conditional_access_policy_definitions
}

# resource "azuread_conditional_access_policy" "this" {
#   for_each = local.conditional_access_policy_definitions

#   display_name = each.value.displayName
#   state        = each.value.state

#   conditions {
#     applications {
#       included_applications = try(each.value.conditions.applications.included_applications, null) != null && try(each.value.conditions.applications.included_user_actions, null) == null ? each.value.conditions.applications.includedApplications : ["all"]
#       excluded_applications = try(each.value.conditions.applications.excluded_applications, null) != null ? each.value.conditions.applications.excludedApplications : null
#       included_user_actions = try(each.value.conditions.applications.included_user_actions, null) != null && try(each.value.conditions.applications.included_applications, null) == null ? each.value.conditions.applications.includedUserActions : null
#     }
#     client_app_types = each.value.conditions.clientAppTypes != null ? each.value.conditions.clientAppTypes : []
#     dynamic "devices" {
#       for_each = try(each.value.conditions.devices, null) != null ? [each.value.conditions.devices] : []
#       content {
#         filter {
#           mode = devices.value.mode
#           rule = devices.value.rule
#         }
#       }
#     }
#     dynamic "client_applications" {
#       for_each = try(each.value.conditions.clientApplications, null) != null ? [each.value.conditions.clientApplications] : []
#       content {
#         excluded_service_principals = try(client_applications.value.excludedServicePrincipals, null) != null ? client_applications.value.excludedServicePrincipals : []
#         included_service_principals = try(client_applications.value.includedServicePrincipals, null) != null ? client_applications.value.includedServicePrincipals : []
#         dynamic "filter" {
#           for_each = try(client_applications.value.filter, null) != null ? [client_applications.value.filter] : []
#           content {
#             mode = filter.value.mode
#             rule = filter.value.rule
#           }
#         }
#       }
#     }
#     insider_risk_levels = try(each.value.conditions.insiderRiskLevels, null) != null ? each.value.conditions.insiderRiskLevels : null
#     dynamic "locations" {
#       for_each = try(each.value.conditions.locations, null) != null ? [each.value.conditions.locations] : []
#       content {
#         included_locations = locations.value.includeLocations != null ? locations.value.includeLocations : []
#         excluded_locations = try(locations.value.excludeLocations, null) != null ? locations.value.excludeLocations : null
#       }
#     }
#     dynamic "platforms" {
#       for_each = try(each.value.conditions.platforms, null) != null ? [each.value.conditions.platforms] : []
#       content {
#         included_platforms = platforms.value.includePlatforms != null ? platforms.value.includePlatforms : []
#         excluded_platforms = try(platforms.value.excludePlatforms, null) != null ? platforms.value.excludePlatforms : []
#       }
#     }
#     service_principal_risk_levels = try(each.value.conditions.servicePrincipalRiskLevels, null) != null ? each.value.conditions.servicePrincipalRiskLevels : null
#     sign_in_risk_levels           = try(each.value.conditions.signInRiskLevels, null) != null ? each.value.conditions.signInRiskLevels : null
#     user_risk_levels              = try(each.value.conditions.userRiskLevels, null) != null ? each.value.conditions.userRiskLevels : null


#     users {
#       excluded_groups = try(each.value.conditions.users.excludeGroups, null) != null ? each.value.conditions.users.excludeGroups : []
#       included_groups = try(each.value.conditions.users.includeGroups, null) != null ? each.value.conditions.users.includeGroups : []
#       excluded_roles  = try(each.value.conditions.users.excludeRoles, null) != null ? each.value.conditions.users.excludeRoles : []
#       included_roles  = try(each.value.conditions.users.includeRoles, null) != null ? each.value.conditions.users.includeRoles : []
#       excluded_users  = try(each.value.conditions.users.excludeUsers, null) != null ? each.value.conditions.users.excludeUsers : []
#       included_users  = try(each.value.conditions.users.includeUsers, null) != null ? each.value.conditions.users.includeUsers : []
#       dynamic "excluded_guests_or_external_users" {
#         for_each = try(each.value.conditions.users.excludeGuestsOrExternalUsers, null) != null ? [each.value.conditions.users.excludeGuestsOrExternalUsers] : []
#         content {
#           dynamic "external_tenants" {
#             for_each = try(excluded_guests_or_external_users.value.externalTenants, null) != null ? [excluded_guests_or_external_users.value.externalTenants] : []
#             content {
#               members         = external_tenants.value.members != null ? external_tenants.value.members : []
#               membership_kind = external_tenants.value.membershipKind
#             }
#           }
#           guest_or_external_user_types = excluded_guests_or_external_users.value.guestOrExternalUserTypes
#         }
#       }
#       dynamic "included_guests_or_external_users" {
#         for_each = try(each.value.conditions.users.includeGuestsOrExternalUsers, null) != null ? [each.value.conditions.users.includeGuestsOrExternalUsers] : []
#         content {
#           dynamic "external_tenants" {
#             for_each = try(included_guests_or_external_users.value.externalTenants, null) != null ? [included_guests_or_external_users.value.externalTenants] : []
#             content {
#               members         = external_tenants.value.members != null ? external_tenants.value.members : []
#               membership_kind = external_tenants.value.membershipKind
#             }
#           }
#           guest_or_external_user_types = included_guests_or_external_users.value.guestOrExternalUserTypes
#         }
#       }
#     }
#   }

#   dynamic "grant_controls" {
#     for_each = try(each.value.grantControls, null) != null ? [each.value.grantControls] : []
#     content {
#       authentication_strength_policy_id = each.value.grantControls.authenticationStrengths != null ? each.value.grantControls.authenticationStrengths : null
#       built_in_controls                 = each.value.grantControls.builtInControls != null ? each.value.grantControls.builtInControls : []
#       terms_of_use                      = each.value.grantControls.termsOfUse != null ? each.value.grantControls.termsOfUse : []
#       custom_authentication_factors     = each.value.grantControls.customAuthenticationFactors != null ? each.value.grantControls.customAuthenticationFactors : []
#       operator                          = "OR"
#     }
#   }

#   dynamic "session_controls" {
#     for_each = try(each.value.sessionControls, null) != null ? [each.value.sessionControls] : []
#     content {
#       application_enforced_restrictions_enabled = true
#       cloud_app_security_policy                 = "monitorOnly"
#       disable_resilience_defaults               = false
#       persistent_browser_mode                   = each.value.sessionControls.persistentBrowser != null ? each.value.sessionControls.persistentBrowser.mode : "always"
#       sign_in_frequency                         = 10
#       sign_in_frequency_authentication_type     = each.value.sessionControls.signInFrequency != null ? each.value.sessionControls.signInFrequency.authenticationTypes : ["all"]
#       sign_in_frequency_interval                = each.value.sessionControls.signInFrequency != null ? each.value.sessionControls.signInFrequency.frequencyInterval : "hours"
#       sign_in_frequency_period                  = "hours"
#     }
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
