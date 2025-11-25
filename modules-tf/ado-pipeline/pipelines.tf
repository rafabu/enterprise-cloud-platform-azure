
locals {
  # do <TERRAFORM_VARIABLE:(.+)> replacement in pipeline definitions
  ado_yaml_pipeline_definitions_replaced = {
    for a in var.ado_yaml_pipeline_artefact_names : a =>

    yamldecode(
      replace(
        yamlencode(var.ado_yaml_pipeline_definitions[a]),
        "/${local.matchpattern_terraform_variable}/",
        var.ecp_environment_name
      )
    )
  }
}

output "zzz_ado_yaml_pipeline_definitions_replaced" {
  value = local.ado_yaml_pipeline_definitions_replaced
}
# {



#   artefactName = val.artefactName
#   displayName  = val.displayName
#   state        = val.state
#   conditions = merge(
#     {
#       for ck, cv in val.conditions : ck => cv
#       if contains(["applications", "clientApplications", "locations"], ck) == false
#     },
#     # conditions/applications: support for GUID, and displayName based references
#     {
#       applications = {
#         includeApplications = distinct(concat(
#           [
#             # GUID of cloud app (client_id)
#             for iApp in try(val.conditions.applications.includeApplications, []) : iApp
#             if length(regexall(local.matchpattern_guid, iApp)) > 0 || contains(["All", "MicrosoftAdminPortals", "Office365"], iApp)
#           ],
#           [
#             # lookup by displayName (cloud app)
#             #     if displayName isn't found (yet), ignore it for now
#             for iApp in try(val.conditions.applications.includeApplications, []) : [
#               for rApp in local.reference_cloud_applications : rApp.appId
#               if rApp.displayName == regexall(local.matchpattern_displayname, iApp)[0][0]
#             ][0]
#             if length(regexall(local.matchpattern_displayname, iApp)) > 0 &&
#             length([
#               for rApp in local.reference_cloud_applications : rApp.appId
#               if rApp.displayName == regexall(local.matchpattern_displayname, iApp)[0][0]
#             ]) > 0
#           ]
#         ))
#         excludeApplications = distinct(concat(
#           [
#             # GUID of cloud app (client_id)
#             for iApp in try(val.conditions.applications.excludeApplications, []) : iApp
#             if length(regexall(local.matchpattern_guid, iApp)) > 0 || contains(["All", "MicrosoftAdminPortals", "Office365"], iApp)
#           ],
#           [
#             # lookup by displayName (cloud app)
#             #     if displayName isn't found (yet), ignore it for now
#             for iApp in try(val.conditions.applications.excludeApplications, []) : [
#               for rApp in local.reference_cloud_applications : rApp.appId
#               if rApp.displayName == regexall(local.matchpattern_displayname, iApp)[0][0]
#             ][0]
#             if length(regexall(local.matchpattern_displayname, iApp)) > 0 &&
#             length([
#               for rApp in local.reference_cloud_applications : rApp.appId
#               if rApp.displayName == regexall(local.matchpattern_displayname, iApp)[0][0]
#             ]) > 0
#           ]
#         ))
#         includeUserActions                          = try(val.conditions.applications.includeUserActions, null) != null ? val.conditions.applications.includeUserActions : null
#         includeAuthenticationContextClassReferences = try(val.conditions.applications.includeAuthenticationContextClassReferences, null) != null ? val.conditions.applications.includeAuthenticationContextClassReferences : []
#         applicationFilter                           = try(val.conditions.applications.applicationFilter, null) != null ? val.conditions.applications.applicationFilter : null
#       }
#     },
#     # conditions/applications: support for GUID, and displayName based references
#     {
#       clientApplications = length(try(val.conditions.clientApplications.includeServicePrincipals, [])) > 0 || length(try(val.conditions.clientApplications.excludeServicePrincipals, [])) > 0 ? {
#         includeServicePrincipals = distinct(concat(
#           [
#             # GUID of cloud app (client_id)
#             for iApp in try(val.conditions.clientApplications.includeServicePrincipals, []) : iApp
#             if length(regexall(local.matchpattern_guid, iApp)) > 0
#           ],
#           [
#             # lookup by displayName (cloud app)
#             #     if displayName isn't found (yet), ignore it for now
#             for iApp in try(val.conditions.clientApplications.includeServicePrincipals, []) : [
#               for rApp in local.reference_client_applications : rApp.appId
#               if regexall("^(?i)${iApp}$", rApp.displayName) != false || regexall("^(?i)${iApp}$", rApp.appId) != false
#             ][0]
#             if length(regexall(local.matchpattern_guid, iApp)) == 0 &&
#             length([
#               for rApp in local.reference_client_applications : rApp.appId
#               if regexall("^(?i)${iApp}$", rApp.displayName) != false || regexall("^(?i)${iApp}$", rApp.appId) != false
#             ]) > 0
#           ]
#         ))
#         excludeServicePrincipals = distinct(concat(
#           [
#             # GUID of cloud app (client_id)
#             for iApp in try(val.conditions.clientApplications.excludeServicePrincipals, []) : iApp
#             if length(regexall(local.matchpattern_guid, iApp)) > 0
#           ],
#           [
#             # lookup by displayName (cloud app)
#             #     if displayName isn't found (yet), ignore it for now
#             for iApp in try(val.conditions.clientApplications.excludeServicePrincipals, []) : [
#               for rApp in local.reference_client_applications : rApp.appId
#               if regexall("^(?i)${iApp}$", rApp.displayName) != false || regexall("^(?i)${iApp}$", rApp.appId) != false
#             ][0]
#             if length(regexall(local.matchpattern_guid, iApp)) == 0 &&
#             length([
#               for rApp in local.reference_client_applications : rApp.appId
#               if regexall("^(?i)${iApp}$", rApp.displayName) != false || regexall("^(?i)${iApp}$", rApp.appId) != false
#             ]) > 0
#           ]
#         ))
#         servicePrincipalFilter = try(val.conditions.clientApplications.servicePrincipalFilter, null) != null ? val.conditions.clientApplications.servicePrincipalFilter : null
#       } : null
#     },
#     # conditions/locations: full support for GUID, ECP artefact and displayName based references
#     {
#       locations = {
#         includeLocations = distinct(concat(
#           [
#             # GUID of named location
#             for iloc in try(val.conditions.locations.includeLocations, []) : iloc
#             if length(regexall(local.matchpattern_guid, iloc)) > 0
#           ],
#           [
#             # lookup ECP artefact (named location)
#             for iloc in try(val.conditions.locations.includeLocations, []) : local.named_location_resources[regexall(local.matchpattern_ecp_artefact, iloc)[0][0]].id
#             if length(regexall(local.matchpattern_ecp_artefact, iloc)) > 0
#           ],
#           [
#             # lookup by displayName (named location)
#             #     if displayName isn't found (yet), ignore it for now
#             for iloc in try(val.conditions.locations.includeLocations, []) : [
#               for nLoc in local.reference_named_locations : nLoc.id
#               if nLoc.displayName == regexall(local.matchpattern_displayname, iloc)[0][0]
#             ][0]
#             if length(regexall(local.matchpattern_displayname, iloc)) > 0 &&
#             length([
#               for nLoc in local.reference_named_locations : nLoc.id
#               if nLoc.displayName == regexall(local.matchpattern_displayname, iloc)[0][0]
#             ]) > 0
#           ]
#         ))
#         excludeLocations = distinct(concat(
#           [
#             # GUID of named location
#             for iloc in try(val.conditions.locations.excludeLocations, []) : iloc
#             if length(regexall(local.matchpattern_guid, iloc)) > 0
#           ],
#           [
#             # lookup ECP artefact (named location)
#             for iloc in try(val.conditions.locations.excludeLocations, []) : local.named_location_resources[regexall(local.matchpattern_ecp_artefact, iloc)[0][0]].id
#             if length(regexall(local.matchpattern_ecp_artefact, iloc)) > 0
#           ],
#           [
#             # lookup by displayName (named location)
#             #     if displayName isn't found (yet), ignore it for now
#             for iloc in try(val.conditions.locations.excludeLocations, []) : [
#               for nLoc in local.reference_named_locations : nLoc.id
#               if nLoc.displayName == regexall(local.matchpattern_displayname, iloc)[0][0]
#             ][0]
#             if length(regexall(local.matchpattern_displayname, iloc)) > 0 &&
#             length([
#               for nLoc in local.reference_named_locations : nLoc.id
#               if nLoc.displayName == regexall(local.matchpattern_displayname, iloc)[0][0]
#             ]) > 0
#           ]
#         ))
#       }
#     },
#     # conditions/users: support for GUID, displayName, mail and userPrincipalName based references
#     {
#       users = {
#         includeUsers = distinct(concat(
#           [
#             # GUID of user (id)
#             for iUsr in try(val.conditions.users.includeUsers, []) : iUsr
#             if length(regexall(local.matchpattern_guid, iUsr)) > 0 || contains(["All", "None"], iUsr)
#           ],
#           [
#             # lookup by displayName (user)
#             #     if displayName isn't found (yet), ignore it for now
#             for iUsr in try(val.conditions.users.includeUsers, []) : [
#               for rUsr in local.reference_includeUsers : rUsr.id
#               if rUsr.displayName == regexall(local.matchpattern_displayname, iUsr)[0][0]
#             ][0]
#             if length(regexall(local.matchpattern_displayname, iUsr)) > 0 &&
#             length([
#               for rUsr in local.reference_includeUsers : rUsr.id
#               if rUsr.displayName == regexall(local.matchpattern_displayname, iUsr)[0][0]
#             ]) > 0
#           ],
#           [
#             # lookup by mail (user)
#             #     if mail isn't found (yet), ignore it for now
#             for iUsr in try(val.conditions.users.includeUsers, []) : [
#               for rUsr in local.reference_includeUsers : rUsr.id
#               if rUsr.mail == regexall(local.matchpattern_mail, iUsr)[0][0]
#             ][0]
#             if length(regexall(local.matchpattern_mail, iUsr)) > 0 &&
#             length([
#               for rUsr in local.reference_includeUsers : rUsr.id
#               if rUsr.mail == regexall(local.matchpattern_mail, iUsr)[0][0]
#             ]) > 0
#           ],
#           [
#             # lookup by userPrincipalName (user)
#             #     if userPrincipalName isn't found (yet), ignore it for now
#             for iUsr in try(val.conditions.users.includeUsers, []) : [
#               for rUsr in local.reference_includeUsers : rUsr.id
#               if rUsr.userPrincipalName == regexall(local.matchpattern_userprincipalname, iUsr)[0][0]
#             ][0]
#             if length(regexall(local.matchpattern_userprincipalname, iUsr)) > 0 &&
#             length([
#               for rUsr in local.reference_includeUsers : rUsr.id
#               if rUsr.userPrincipalName == regexall(local.matchpattern_userprincipalname, iUsr)[0][0]
#             ]) > 0
#           ]
#         ))
#         excludeUsers = distinct(concat(
#           [
#             # GUID of user (id)
#             for iUsr in try(val.conditions.users.excludeUsers, []) : iUsr
#             if length(regexall(local.matchpattern_guid, iUsr)) > 0
#           ],
#           [
#             # lookup by displayName (user)
#             #     if displayName isn't found (yet), ignore it for now
#             for iUsr in try(val.conditions.users.excludeUsers, []) : [
#               for rUsr in local.reference_excludeUsers : rUsr.id
#               if rUsr.displayName == regexall(local.matchpattern_displayname, iUsr)[0][0]
#             ][0]
#             if length(regexall(local.matchpattern_displayname, iUsr)) > 0 &&
#             length([
#               for rUsr in local.reference_excludeUsers : rUsr.id
#               if rUsr.displayName == regexall(local.matchpattern_displayname, iUsr)[0][0]
#             ]) > 0
#           ],
#           [
#             # lookup by mail (user)
#             #     if mail isn't found (yet), ignore it for now
#             for iUsr in try(val.conditions.users.excludeUsers, []) : [
#               for rUsr in local.reference_excludeUsers : rUsr.id
#               if rUsr.mail == regexall(local.matchpattern_mail, iUsr)[0][0]
#             ][0]
#             if length(regexall(local.matchpattern_mail, iUsr)) > 0 &&
#             length([
#               for rUsr in local.reference_excludeUsers : rUsr.id
#               if rUsr.mail == regexall(local.matchpattern_mail, iUsr)[0][0]
#             ]) > 0
#           ],
#           [
#             # lookup by userPrincipalName (user)
#             #     if userPrincipalName isn't found (yet), ignore it for now
#             for iUsr in try(val.conditions.users.excludeUsers, []) : [
#               for rUsr in local.reference_excludeUsers : rUsr.id
#               if rUsr.userPrincipalName == regexall(local.matchpattern_userprincipalname, iUsr)[0][0]
#             ][0]
#             if length(regexall(local.matchpattern_userprincipalname, iUsr)) > 0 &&
#             length([
#               for rUsr in local.reference_excludeUsers : rUsr.id
#               if rUsr.userPrincipalName == regexall(local.matchpattern_userprincipalname, iUsr)[0][0]
#             ]) > 0
#           ]
#         ))
#         includeGroups = distinct(concat(
#           [
#             # GUID of group (id)
#             for iGrp in try(val.conditions.users.includeGroups, []) : iGrp
#             if length(regexall(local.matchpattern_guid, iGrp)) > 0
#           ],
#           [
#             # lookup by displayName (group)
#             #     if displayName isn't found (yet), ignore it for now
#             for iGrp in try(val.conditions.users.includeGroups, []) : [
#               for rGrp in local.reference_groups : rGrp.id
#               if rGrp.displayName == regexall(local.matchpattern_displayname, iGrp)[0][0]
#             ][0]
#             if length(regexall(local.matchpattern_displayname, iGrp)) > 0 &&
#             length([
#               for rGrp in local.reference_groups : rGrp.id
#               if rGrp.displayName == regexall(local.matchpattern_displayname, iGrp)[0][0]
#             ]) > 0
#           ],
#           [
#             # lookup by mail (group)
#             #     if mail isn't found (yet), ignore it for now
#             for iGrp in try(val.conditions.users.includeGroups, []) : [
#               for rGrp in local.reference_groups : rGrp.id
#               if rGrp.mail == regexall(local.matchpattern_mail, iGrp)[0][0]
#             ][0]
#             if length(regexall(local.matchpattern_mail, iGrp)) > 0 &&
#             length([
#               for rGrp in local.reference_groups : rGrp.id
#               if rGrp.mail == regexall(local.matchpattern_mail, iGrp)[0][0]
#             ]) > 0
#           ]
#         ))
#         excludeGroups = distinct(concat(
#           [
#             # GUID of group (id)
#             for iGrp in try(val.conditions.users.excludeGroups, []) : iGrp
#             if length(regexall(local.matchpattern_guid, iGrp)) > 0
#           ],
#           [
#             # lookup by displayName (group)
#             #     if displayName isn't found (yet), ignore it for now
#             for iGrp in try(val.conditions.users.excludeGroups, []) : [
#               for rGrp in local.reference_groups : rGrp.id
#               if rGrp.displayName == regexall(local.matchpattern_displayname, iGrp)[0][0]
#             ][0]
#             if length(regexall(local.matchpattern_displayname, iGrp)) > 0 &&
#             length([
#               for rGrp in local.reference_groups : rGrp.id
#               if rGrp.displayName == regexall(local.matchpattern_displayname, iGrp)[0][0]
#             ]) > 0
#           ],
#           [
#             # lookup by mail (group)
#             #     if mail isn't found (yet), ignore it for now
#             for iGrp in try(val.conditions.users.excludeGroups, []) : [
#               for rGrp in local.reference_groups : rGrp.id
#               if rGrp.mail == regexall(local.matchpattern_mail, iGrp)[0][0]
#             ][0]
#             if length(regexall(local.matchpattern_mail, iGrp)) > 0 &&
#             length([
#               for rGrp in local.reference_groups : rGrp.id
#               if rGrp.mail == regexall(local.matchpattern_mail, iGrp)[0][0]
#             ]) > 0
#           ]
#         ))
#         includeRoles = distinct(concat(
#           [
#             # GUID of directory role (id)
#             for iRle in try(val.conditions.users.includeRoles, []) : iRle
#             if length(regexall(local.matchpattern_guid, iRle)) > 0
#           ],
#           [
#             # lookup by displayName (directory role)
#             #     if displayName isn't found (yet), ignore it for now
#             for iRle in try(val.conditions.users.includeRoles, []) : [
#               for rRle in local.reference_directory_roles : rRle.id
#               if rRle.displayName == regexall(local.matchpattern_displayname, iRle)[0][0]
#             ][0]
#             if length(regexall(local.matchpattern_displayname, iRle)) > 0 &&
#             length([
#               for rRle in local.reference_directory_roles : rRle.id
#               if rRle.displayName == regexall(local.matchpattern_displayname, iRle)[0][0]
#             ]) > 0
#           ]
#         ))
#         excludeRoles = distinct(concat(
#           [
#             # GUID of directory role (id)
#             for iRle in try(val.conditions.users.excludeRoles, []) : iRle
#             if length(regexall(local.matchpattern_guid, iRle)) > 0
#           ],
#           [
#             # lookup by displayName (directory role)
#             #     if displayName isn't found (yet), ignore it for now
#             for iRle in try(val.conditions.users.excludeRoles, []) : [
#               for rRle in local.reference_directory_roles : rRle.id
#               if rRle.displayName == regexall(local.matchpattern_displayname, iRle)[0][0]
#             ][0]
#             if length(regexall(local.matchpattern_displayname, iRle)) > 0 &&
#             length([
#               for rRle in local.reference_directory_roles : rRle.id
#               if rRle.displayName == regexall(local.matchpattern_displayname, iRle)[0][0]
#             ]) > 0
#           ]
#         ))
#         includeGuestsOrExternalUsers = try(val.conditions.users.includeGuestsOrExternalUsers, null) != null ? val.conditions.users.includeGuestsOrExternalUsers : null
#         excludeGuestsOrExternalUsers = try(val.conditions.users.excludeGuestsOrExternalUsers, null) != null ? val.conditions.users.excludeGuestsOrExternalUsers : null
#       }
#     },
#   )
#   grantControls   = try(val.grantControls, null) != null ? val.grantControls : null
#   sessionControls = try(val.sessionControls, null) != null ? val.sessionControls : null
# }

data "azuredevops_project" "this" {
  name = var.ecp_azure_devops_project_name
}

data "azuredevops_git_repository" "this" {
  project_id = data.azuredevops_project.this.id
  name       = var.ecp_azure_devops_repository_name
}

# data "azuredevops_serviceendpoint_azurerm" "this" { 
#   project_id = data.azuredevops_project.this.id
#   name       = "Azure-${local.resource_group.name}-ServiceConnection"
# }

resource "azuredevops_build_definition" "pipelines" {
  for_each = toset(var.ado_yaml_pipeline_artefact_names)

  project_id = data.azuredevops_project.this.id
  name       = var.ado_yaml_pipeline_definitions[each.key].nameElement
  path       = coalesce(var.ado_yaml_pipeline_definitions[each.key].path, "\\")

  agent_pool_name = coalesce(var.ado_yaml_pipeline_definitions[each.key].queue.name, "Azure Pipelines")
  #  A list of variable group IDs (integers) 
  variable_groups = null # []
  variable {
    name  = "environment"
    value = "dev"
  }
  features {
    skip_first_run = coalesce(var.ado_yaml_pipeline_definitions[each.key].skipFirstRun, true)
  }
  queue_status            = coalesce(var.ado_yaml_pipeline_definitions[each.key].queueStatus, "enabled")
  job_authorization_scope = coalesce(var.ado_yaml_pipeline_definitions[each.key].jobAuthorizationScope, "projectCollection")

  ci_trigger {
    use_yaml = true
    # forks {
    #   enabled = false
    #   share_secrets = false
    # }
  }

  repository {
    repo_id             = data.azuredevops_git_repository.this.id
    repo_type           = coalesce(var.ado_yaml_pipeline_definitions[each.key].repository.type, "TfsGit")
    branch_name         = coalesce(var.ado_yaml_pipeline_definitions[each.key].repository.defaultBranch, "refs/heads/main")
    yml_path            = var.ado_yaml_pipeline_definitions[each.key].process.yamlFilename
    report_build_status = try(var.ado_yaml_pipeline_definitions[each.key].repository.properties.reportBuildStatus, true)
  }

  # Variable Groups
  # dynamic "variable_groups" {
  #   for_each = each.value.variable_group_ids != null ? each.value.variable_group_ids : []
  #   content {
  #     variable_groups.value
  #   }
  # }

  # # Variables
  # dynamic "variable" {
  #   for_each = each.value.variables != null ? each.value.variables : {}
  #   content {
  #     name           = variable.key
  #     value          = variable.value.value
  #     is_secret      = try(variable.value.is_secret, false)
  #     allow_override = try(variable.value.allow_override, true)
  #   }
  # }

  # Features


  # Queue settings
  # dynamic "queue" {
  #   for_each = each.value.agent_pool_name != null ? [1] : []  
  #   content {
  #     agent_pool_name = each.value.agent_pool_name
  #   }
  # }

  # schedules {}

  depends_on = [
    azuredevops_environment.ecp,
    azuredevops_build_folder.two
  ]
}

# # Build Definition Permissions
# resource "azuredevops_build_definition_permissions" "pipeline_permissions" {
#   for_each = {
#     for key, pipeline in var.ado_pipeline_definitions : key => pipeline
#     if pipeline.permissions != null
#   }

#   project_id          = data.azuredevops_project.this.id
#   principal           = each.value.permissions.principal
#   build_definition_id = azuredevops_build_definition.pipelines[each.key].id
#   permissions         = each.value.permissions.permissions
# }
locals {
  pip_env_list = [
    for pip_item in var.ado_yaml_pipeline_artefact_names : {
      for env_key, env_value in local.ecp_pipeline_environments :
      "${pip_item}-${env_key}" => {
        pip_item  = pip_item
        env_key   = env_key
        env_value = env_value
      }
    }
  ]
  pip_env_object = zipmap(
    flatten([for entry, attr in local.pip_env_list : keys(attr)]),
    flatten([for entry, attr in local.pip_env_list : values(attr)])
  )
}

# # Environment Resource Authorization
resource "azuredevops_pipeline_authorization" "ecp_environment" {
  # for_each = toset(var.ado_yaml_pipeline_artefact_names)

  for_each = local.pip_env_object

  project_id          = data.azuredevops_project.this.id
  resource_id         = azuredevops_environment.ecp[each.value.env_key].id
  type                = "environment"
  pipeline_id         = azuredevops_build_definition.pipelines[each.value.pip_item].id
  pipeline_project_id = null
}

# # Service Connection Authorization  
# resource "azuredevops_resource_authorization" "service_connection_auth" {
#   for_each = {
#     for key, pipeline in var.ado_pipeline_definitions : key => pipeline
#     if var.create_service_connection && pipeline.authorize_service_connection == true
#   }

#   project_id    = data.azuredevops_project.this.id
#   resource_id   = azuredevops_serviceendpoint_azurerm.pipeline_service_connection[0].id
#   definition_id = azuredevops_build_definition.pipelines[each.key].id
#   authorized    = true
#   type          = "endpoint"
# }
