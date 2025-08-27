locals {
  # conditionalaccessPolicy
  # look for references and put in their IDs of the following types:
  #   - cloudApp (servicePrincipal) --> appId, displayname, known logical names
  #   - namedLocation --> id, displayname, ECP artefact
  #   - clientApplications --> appId, displayname
  #   - users --> id, displayname, mail, userPrincipalName
  #   - groups --> id, displayname, mail
  #   - roles --> id, displayname
  #
  #   if names etc. cannot be resolved, they are excluded from that plan
  conditional_access_policy_definitions = {
    for key, val in var.conditional_access_policy_definitions : key => {
      artefactName = val.artefactName
      displayName  = val.displayName
      state        = val.state
      conditions = merge(
        {
          for ck, cv in val.conditions : ck => cv
          if contains(["applications", "clientApplications", "locations"], ck) == false
        },
        # conditions/applications: support for GUID, and displayName based references
        {
          applications = {
            includeApplications = distinct(concat(
              [
                # GUID of cloud app (client_id)
                for iApp in try(val.conditions.applications.includeApplications, []) : iApp
                if length(regexall(local.matchpattern_guid, iApp)) > 0 || contains(["All", "MicrosoftAdminPortals", "Office365"], iApp)
              ],
              [
                # lookup by displayName (cloud app)
                #     if displayName isn't found (yet), ignore it for now
                for iApp in try(val.conditions.applications.includeApplications, []) : [
                  for rApp in local.reference_cloud_applications : rApp.appId
                  if rApp.displayName == regexall(local.matchpattern_displayname, iApp)[0][0]
                ][0]
                if length(regexall(local.matchpattern_displayname, iApp)) > 0 &&
                length([
                  for rApp in local.reference_cloud_applications : rApp.appId
                  if rApp.displayName == regexall(local.matchpattern_displayname, iApp)[0][0]
                ]) > 0
              ]
            ))
            excludeApplications = distinct(concat(
              [
                # GUID of cloud app (client_id)
                for iApp in try(val.conditions.applications.excludeApplications, []) : iApp
                if length(regexall(local.matchpattern_guid, iApp)) > 0 || contains(["All", "MicrosoftAdminPortals", "Office365"], iApp)
              ],
              [
                # lookup by displayName (cloud app)
                #     if displayName isn't found (yet), ignore it for now
                for iApp in try(val.conditions.applications.excludeApplications, []) : [
                  for rApp in local.reference_cloud_applications : rApp.appId
                  if rApp.displayName == regexall(local.matchpattern_displayname, iApp)[0][0]
                ][0]
                if length(regexall(local.matchpattern_displayname, iApp)) > 0 &&
                length([
                  for rApp in local.reference_cloud_applications : rApp.appId
                  if rApp.displayName == regexall(local.matchpattern_displayname, iApp)[0][0]
                ]) > 0
              ]
            ))
            includeUserActions                          = try(val.conditions.applications.includeUserActions, null) != null ? val.conditions.applications.includeUserActions : null
            includeAuthenticationContextClassReferences = try(val.conditions.applications.includeAuthenticationContextClassReferences, null) != null ? val.conditions.applications.includeAuthenticationContextClassReferences : []
            applicationFilter                           = try(val.conditions.applications.applicationFilter, null) != null ? val.conditions.applications.applicationFilter : null
          }
        },
        # conditions/applications: support for GUID, and displayName based references
        {
          clientApplications = length(try(val.conditions.clientApplications.includeServicePrincipals, [])) > 0 || length(try(val.conditions.clientApplications.excludeServicePrincipals, [])) > 0 ? {
            includeServicePrincipals = distinct(concat(
              [
                # GUID of cloud app (client_id)
                for iApp in try(val.conditions.clientApplications.includeServicePrincipals, []) : iApp
                if length(regexall(local.matchpattern_guid, iApp)) > 0
              ],
              [
                # lookup by displayName (cloud app)
                #     if displayName isn't found (yet), ignore it for now
                for iApp in try(val.conditions.clientApplications.includeServicePrincipals, []) : [
                  for rApp in local.reference_client_applications : rApp.appId
                  if regexall("^(?i)${iApp}$", rApp.displayName) != false || regexall("^(?i)${iApp}$", rApp.appId) != false
                ][0]
                if length(regexall(local.matchpattern_guid, iApp)) == 0 &&
                length([
                  for rApp in local.reference_client_applications : rApp.appId
                  if regexall("^(?i)${iApp}$", rApp.displayName) != false || regexall("^(?i)${iApp}$", rApp.appId) != false
                ]) > 0
              ]
            ))
            excludeServicePrincipals = distinct(concat(
              [
                # GUID of cloud app (client_id)
                for iApp in try(val.conditions.clientApplications.excludeServicePrincipals, []) : iApp
                if length(regexall(local.matchpattern_guid, iApp)) > 0
              ],
              [
                # lookup by displayName (cloud app)
                #     if displayName isn't found (yet), ignore it for now
                for iApp in try(val.conditions.clientApplications.excludeServicePrincipals, []) : [
                  for rApp in local.reference_client_applications : rApp.appId
                  if regexall("^(?i)${iApp}$", rApp.displayName) != false || regexall("^(?i)${iApp}$", rApp.appId) != false
                ][0]
                if length(regexall(local.matchpattern_guid, iApp)) == 0 &&
                length([
                  for rApp in local.reference_client_applications : rApp.appId
                  if regexall("^(?i)${iApp}$", rApp.displayName) != false || regexall("^(?i)${iApp}$", rApp.appId) != false
                ]) > 0
              ]
            ))
            servicePrincipalFilter = try(val.conditions.clientApplications.servicePrincipalFilter, null) != null ? val.conditions.clientApplications.servicePrincipalFilter : null
          } : null
        },
        # conditions/locations: full support for GUID, ECP artefact and displayName based references
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
                  for nLoc in local.reference_named_locations : nLoc.id
                  if nLoc.displayName == regexall(local.matchpattern_displayname, iloc)[0][0]
                ][0]
                if length(regexall(local.matchpattern_displayname, iloc)) > 0 &&
                length([
                  for nLoc in local.reference_named_locations : nLoc.id
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
                  for nLoc in local.reference_named_locations : nLoc.id
                  if nLoc.displayName == regexall(local.matchpattern_displayname, iloc)[0][0]
                ][0]
                if length(regexall(local.matchpattern_displayname, iloc)) > 0 &&
                length([
                  for nLoc in local.reference_named_locations : nLoc.id
                  if nLoc.displayName == regexall(local.matchpattern_displayname, iloc)[0][0]
                ]) > 0
              ]
            ))
          }
        },
        # conditions/users: support for GUID, displayName, mail and userPrincipalName based references
        {
          users = {
            includeUsers = distinct(concat(
              [
                # GUID of user (id)
                for iUsr in try(val.conditions.users.includeUsers, []) : iUsr
                if length(regexall(local.matchpattern_guid, iUsr)) > 0 || contains(["All", "None"], iUsr)
              ],
              [
                # lookup by displayName (user)
                #     if displayName isn't found (yet), ignore it for now
                for iUsr in try(val.conditions.users.includeUsers, []) : [
                  for rUsr in local.reference_includeUsers : rUsr.id
                  if rUsr.displayName == regexall(local.matchpattern_displayname, iUsr)[0][0]
                ][0]
                if length(regexall(local.matchpattern_displayname, iUsr)) > 0 &&
                length([
                  for rUsr in local.reference_includeUsers : rUsr.id
                  if rUsr.displayName == regexall(local.matchpattern_displayname, iUsr)[0][0]
                ]) > 0
              ],
              [
                # lookup by mail (user)
                #     if mail isn't found (yet), ignore it for now
                for iUsr in try(val.conditions.users.includeUsers, []) : [
                  for rUsr in local.reference_includeUsers : rUsr.id
                  if rUsr.mail == regexall(local.matchpattern_mail, iUsr)[0][0]
                ][0]
                if length(regexall(local.matchpattern_mail, iUsr)) > 0 &&
                length([
                  for rUsr in local.reference_includeUsers : rUsr.id
                  if rUsr.mail == regexall(local.matchpattern_mail, iUsr)[0][0]
                ]) > 0
              ],
              [
                # lookup by userPrincipalName (user)
                #     if userPrincipalName isn't found (yet), ignore it for now
                for iUsr in try(val.conditions.users.includeUsers, []) : [
                  for rUsr in local.reference_includeUsers : rUsr.id
                  if rUsr.userPrincipalName == regexall(local.matchpattern_userprincipalname, iUsr)[0][0]
                ][0]
                if length(regexall(local.matchpattern_userprincipalname, iUsr)) > 0 &&
                length([
                  for rUsr in local.reference_includeUsers : rUsr.id
                  if rUsr.userPrincipalName == regexall(local.matchpattern_userprincipalname, iUsr)[0][0]
                ]) > 0
              ]
            ))
            excludeUsers = distinct(concat(
              [
                # GUID of user (id)
                for iUsr in try(val.conditions.users.excludeUsers, []) : iUsr
                if length(regexall(local.matchpattern_guid, iUsr)) > 0
              ],
              [
                # lookup by displayName (user)
                #     if displayName isn't found (yet), ignore it for now
                for iUsr in try(val.conditions.users.excludeUsers, []) : [
                  for rUsr in local.reference_excludeUsers : rUsr.id
                  if rUsr.displayName == regexall(local.matchpattern_displayname, iUsr)[0][0]
                ][0]
                if length(regexall(local.matchpattern_displayname, iUsr)) > 0 &&
                length([
                  for rUsr in local.reference_excludeUsers : rUsr.id
                  if rUsr.displayName == regexall(local.matchpattern_displayname, iUsr)[0][0]
                ]) > 0
              ],
              [
                # lookup by mail (user)
                #     if mail isn't found (yet), ignore it for now
                for iUsr in try(val.conditions.users.excludeUsers, []) : [
                  for rUsr in local.reference_excludeUsers : rUsr.id
                  if rUsr.mail == regexall(local.matchpattern_mail, iUsr)[0][0]
                ][0]
                if length(regexall(local.matchpattern_mail, iUsr)) > 0 &&
                length([
                  for rUsr in local.reference_excludeUsers : rUsr.id
                  if rUsr.mail == regexall(local.matchpattern_mail, iUsr)[0][0]
                ]) > 0
              ],
              [
                # lookup by userPrincipalName (user)
                #     if userPrincipalName isn't found (yet), ignore it for now
                for iUsr in try(val.conditions.users.excludeUsers, []) : [
                  for rUsr in local.reference_excludeUsers : rUsr.id
                  if rUsr.userPrincipalName == regexall(local.matchpattern_userprincipalname, iUsr)[0][0]
                ][0]
                if length(regexall(local.matchpattern_userprincipalname, iUsr)) > 0 &&
                length([
                  for rUsr in local.reference_excludeUsers : rUsr.id
                  if rUsr.userPrincipalName == regexall(local.matchpattern_userprincipalname, iUsr)[0][0]
                ]) > 0
              ]
            ))
            includeGroups = distinct(concat(
              [
                # GUID of group (id)
                for iGrp in try(val.conditions.users.includeGroups, []) : iGrp
                if length(regexall(local.matchpattern_guid, iGrp)) > 0
              ],
              [
                # lookup by displayName (group)
                #     if displayName isn't found (yet), ignore it for now
                for iGrp in try(val.conditions.users.includeGroups, []) : [
                  for rGrp in local.reference_groups : rGrp.id
                  if rGrp.displayName == regexall(local.matchpattern_displayname, iGrp)[0][0]
                ][0]
                if length(regexall(local.matchpattern_displayname, iGrp)) > 0 &&
                length([
                  for rGrp in local.reference_groups : rGrp.id
                  if rGrp.displayName == regexall(local.matchpattern_displayname, iGrp)[0][0]
                ]) > 0
              ],
              [
                # lookup by mail (group)
                #     if mail isn't found (yet), ignore it for now
                for iGrp in try(val.conditions.users.includeGroups, []) : [
                  for rGrp in local.reference_groups : rGrp.id
                  if rGrp.mail == regexall(local.matchpattern_mail, iGrp)[0][0]
                ][0]
                if length(regexall(local.matchpattern_mail, iGrp)) > 0 &&
                length([
                  for rGrp in local.reference_groups : rGrp.id
                  if rGrp.mail == regexall(local.matchpattern_mail, iGrp)[0][0]
                ]) > 0
              ]
            ))
            excludeGroups = distinct(concat(
              [
                # GUID of group (id)
                for iGrp in try(val.conditions.users.excludeGroups, []) : iGrp
                if length(regexall(local.matchpattern_guid, iGrp)) > 0
              ],
              [
                # lookup by displayName (group)
                #     if displayName isn't found (yet), ignore it for now
                for iGrp in try(val.conditions.users.excludeGroups, []) : [
                  for rGrp in local.reference_groups : rGrp.id
                  if rGrp.displayName == regexall(local.matchpattern_displayname, iGrp)[0][0]
                ][0]
                if length(regexall(local.matchpattern_displayname, iGrp)) > 0 &&
                length([
                  for rGrp in local.reference_groups : rGrp.id
                  if rGrp.displayName == regexall(local.matchpattern_displayname, iGrp)[0][0]
                ]) > 0
              ],
              [
                # lookup by mail (group)
                #     if mail isn't found (yet), ignore it for now
                for iGrp in try(val.conditions.users.excludeGroups, []) : [
                  for rGrp in local.reference_groups : rGrp.id
                  if rGrp.mail == regexall(local.matchpattern_mail, iGrp)[0][0]
                ][0]
                if length(regexall(local.matchpattern_mail, iGrp)) > 0 &&
                length([
                  for rGrp in local.reference_groups : rGrp.id
                  if rGrp.mail == regexall(local.matchpattern_mail, iGrp)[0][0]
                ]) > 0
              ]
            ))
            includeRoles = distinct(concat(
              [
                # GUID of directory role (id)
                for iRle in try(val.conditions.users.includeRoles, []) : iRle
                if length(regexall(local.matchpattern_guid, iRle)) > 0
              ],
              [
                # lookup by displayName (directory role)
                #     if displayName isn't found (yet), ignore it for now
                for iRle in try(val.conditions.users.includeRoles, []) : [
                  for rRle in local.reference_directory_roles : rRle.id
                  if rRle.displayName == regexall(local.matchpattern_displayname, iRle)[0][0]
                ][0]
                if length(regexall(local.matchpattern_displayname, iRle)) > 0 &&
                length([
                  for rRle in local.reference_directory_roles : rRle.id
                  if rRle.displayName == regexall(local.matchpattern_displayname, iRle)[0][0]
                ]) > 0
              ]
            ))
            excludeRoles = distinct(concat(
              [
                # GUID of directory role (id)
                for iRle in try(val.conditions.users.excludeRoles, []) : iRle
                if length(regexall(local.matchpattern_guid, iRle)) > 0
              ],
              [
                # lookup by displayName (directory role)
                #     if displayName isn't found (yet), ignore it for now
                for iRle in try(val.conditions.users.excludeRoles, []) : [
                  for rRle in local.reference_directory_roles : rRle.id
                  if rRle.displayName == regexall(local.matchpattern_displayname, iRle)[0][0]
                ][0]
                if length(regexall(local.matchpattern_displayname, iRle)) > 0 &&
                length([
                  for rRle in local.reference_directory_roles : rRle.id
                  if rRle.displayName == regexall(local.matchpattern_displayname, iRle)[0][0]
                ]) > 0
              ]
            ))
            includeGuestsOrExternalUsers = try(val.conditions.users.includeGuestsOrExternalUsers, null) != null ? val.conditions.users.includeGuestsOrExternalUsers : null
            excludeGuestsOrExternalUsers = try(val.conditions.users.excludeGuestsOrExternalUsers, null) != null ? val.conditions.users.excludeGuestsOrExternalUsers : null
          }
        },
      )
      grantControls   = try(val.grantControls, null) != null ? val.grantControls : null
      sessionControls = try(val.sessionControls, null) != null ? val.sessionControls : null
    }
  }
}

resource "azuread_conditional_access_policy" "this" {
  for_each = local.conditional_access_policy_definitions

  display_name = each.value.displayName
  state        = each.value.state

  conditions {
    applications {
      included_applications = try(each.value.conditions.applications.includeApplications, null) != null && length(try(each.value.conditions.applications.includeUserActions, [])) == 0 ? each.value.conditions.applications.includeApplications : ["All"]
      excluded_applications = try(each.value.conditions.applications.excludeApplications, null) != null ? each.value.conditions.applications.excludeApplications : null
      included_user_actions = length(try(each.value.conditions.applications.includeUserActions, [])) > 0 && try(each.value.conditions.applications.includeApplications, null) == null ? each.value.conditions.applications.includeUserActions : null
    }
    client_app_types = each.value.conditions.clientAppTypes != null ? each.value.conditions.clientAppTypes : []
    dynamic "devices" {
      for_each = try(each.value.conditions.devices, null) != null ? [each.value.conditions.devices] : []
      content {
        filter {
          mode = devices.value.mode
          rule = devices.value.rule
        }
      }
    }
    dynamic "client_applications" {
      for_each = try(each.value.conditions.clientApplications, null) != null ? [each.value.conditions.clientApplications] : []
      content {
        excluded_service_principals = try(client_applications.value.excludeServicePrincipals, null) != null ? client_applications.value.excludeServicePrincipals : []
        included_service_principals = try(client_applications.value.includeServicePrincipals, null) != null ? client_applications.value.includeServicePrincipals : []
        dynamic "filter" {
          for_each = try(client_applications.value.servicePrincipalFilter, null) != null ? [client_applications.value.servicePrincipalFilter] : []
          content {
            mode = filter.value.mode
            rule = filter.value.rule
          }
        }
      }
    }
    insider_risk_levels = try(each.value.conditions.insiderRiskLevels, null) != null ? each.value.conditions.insiderRiskLevels : null
    dynamic "locations" {
      for_each = try(each.value.conditions.locations, null) != null ? [each.value.conditions.locations] : []
      content {
        included_locations = locations.value.includeLocations != null ? locations.value.includeLocations : []
        excluded_locations = try(locations.value.excludeLocations, null) != null ? locations.value.excludeLocations : null
      }
    }
    dynamic "platforms" {
      for_each = try(each.value.conditions.platforms, null) != null ? [each.value.conditions.platforms] : []
      content {
        included_platforms = platforms.value.includePlatforms != null ? platforms.value.includePlatforms : []
        excluded_platforms = try(platforms.value.excludePlatforms, null) != null ? platforms.value.excludePlatforms : []
      }
    }
    service_principal_risk_levels = try(each.value.conditions.servicePrincipalRiskLevels, null) != null ? each.value.conditions.servicePrincipalRiskLevels : null
    sign_in_risk_levels           = try(each.value.conditions.signInRiskLevels, null) != null ? each.value.conditions.signInRiskLevels : null
    user_risk_levels              = try(each.value.conditions.userRiskLevels, null) != null ? each.value.conditions.userRiskLevels : null


    users {
      excluded_groups = try(each.value.conditions.users.excludeGroups, null) != null ? each.value.conditions.users.excludeGroups : []
      included_groups = try(each.value.conditions.users.includeGroups, null) != null ? each.value.conditions.users.includeGroups : []
      excluded_roles  = try(each.value.conditions.users.excludeRoles, null) != null ? each.value.conditions.users.excludeRoles : []
      included_roles  = try(each.value.conditions.users.includeRoles, null) != null ? each.value.conditions.users.includeRoles : []
      excluded_users  = try(each.value.conditions.users.excludeUsers, null) != null ? each.value.conditions.users.excludeUsers : []
      included_users  = try(each.value.conditions.users.includeUsers, null) != null ? each.value.conditions.users.includeUsers : []
      dynamic "excluded_guests_or_external_users" {
        for_each = try(each.value.conditions.users.excludeGuestsOrExternalUsers, null) != null ? [each.value.conditions.users.excludeGuestsOrExternalUsers] : []
        content {
          dynamic "external_tenants" {
            for_each = try(excluded_guests_or_external_users.value.externalTenants, null) != null ? [excluded_guests_or_external_users.value.externalTenants] : []
            content {
              members         = external_tenants.value.membershipKind == "enumerated" ? external_tenants.value.members : null
              membership_kind = external_tenants.value.membershipKind
            }
          }
          guest_or_external_user_types = split(",", excluded_guests_or_external_users.value.guestOrExternalUserTypes)
        }
      }
      dynamic "included_guests_or_external_users" {
        for_each = try(each.value.conditions.users.includeGuestsOrExternalUsers, null) != null ? [each.value.conditions.users.includeGuestsOrExternalUsers] : []
        content {
          dynamic "external_tenants" {
            for_each = try(included_guests_or_external_users.value.externalTenants, null) != null ? [included_guests_or_external_users.value.externalTenants] : []
            content {
              members         = external_tenants.value.membershipKind == "enumerated" ? external_tenants.value.members : null
              membership_kind = external_tenants.value.membershipKind
            }
          }
          guest_or_external_user_types = split(",", included_guests_or_external_users.value.guestOrExternalUserTypes)
        }
      }
    }
  }

  dynamic "grant_controls" {
    for_each = try(each.value.grantControls, null) != null ? [each.value.grantControls] : []
    content {
      authentication_strength_policy_id = each.value.grantControls.authenticationStrengths != null ? each.value.grantControls.authenticationStrengths : null
      built_in_controls                 = each.value.grantControls.builtInControls != null ? each.value.grantControls.builtInControls : []
      terms_of_use                      = each.value.grantControls.termsOfUse != null ? each.value.grantControls.termsOfUse : []
      custom_authentication_factors     = each.value.grantControls.customAuthenticationFactors != null ? each.value.grantControls.customAuthenticationFactors : []
      operator                          = "OR"
    }
  }

  dynamic "session_controls" {
    for_each = try(each.value.sessionControls, null) != null ? [each.value.sessionControls] : []
    content {
      application_enforced_restrictions_enabled = true
      cloud_app_security_policy                 = "monitorOnly"
      disable_resilience_defaults               = false
      persistent_browser_mode                   = each.value.sessionControls.persistentBrowser != null ? each.value.sessionControls.persistentBrowser.mode : "always"
      sign_in_frequency                         = 10
      sign_in_frequency_authentication_type     = each.value.sessionControls.signInFrequency != null ? each.value.sessionControls.signInFrequency.authenticationTypes : ["all"]
      sign_in_frequency_interval                = each.value.sessionControls.signInFrequency != null ? each.value.sessionControls.signInFrequency.frequencyInterval : "hours"
      sign_in_frequency_period                  = "hours"
    }
  }

  timeouts {
    create = "10m"
    delete = "10m"
  }

  depends_on = [terraform_data.policy_identity_security_defaults_enforcement_update]

  lifecycle {
    precondition {
      condition     = local.reference_directory_license_level != "AAD_FREE"
      error_message = "Conditional Access requires Entra ID Premium P1 or P2 license. However, the tenant is currently at license level: ${local.reference_directory_license_level}."
    }
  }
}

output "conditional_access_policy" {
  value = { for key, val in azuread_conditional_access_policy.this : key => {
    id           = split("/", val.id)[length(split("/", val.id)) - 1]
    display_name = val.display_name
    state        = val.state
    }
  }
}
