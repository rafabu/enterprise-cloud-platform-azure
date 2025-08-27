####################################################
# Entra Licenses Level (universal)
####################################################
data "msgraph_resource" "reference_subscribed_skus_aad_premium_p1" {
  url         = "subscribedSkus?$select=skuPartNumber,servicePlans"
  api_version = "v1.0"
  response_export_values = {
    subscribedSkus = "value[?(@.servicePlans[?(@.servicePlanName=='AAD_PREMIUM_P1')])].{skuPartNumber:skuPartNumber}"
  }
}

data "msgraph_resource" "reference_subscribed_skus_aad_premium_p2" {
  url         = "subscribedSkus?$select=skuPartNumber,servicePlans"
  api_version = "v1.0"
  response_export_values = {
    subscribedSkus = "value[?(@.servicePlans[?(@.servicePlanName=='AAD_PREMIUM_P2')])].{skuPartNumber:skuPartNumber}"
  }
}

locals {
  reference_directory_license_level = length(
    data.msgraph_resource.reference_subscribed_skus_aad_premium_p2.output.subscribedSkus
    ) > 0 ? "AAD_PREMIUM_P2" : (
    length(
      data.msgraph_resource.reference_subscribed_skus_aad_premium_p1.output.subscribedSkus
    ) > 0 ? "AAD_PREMIUM_P1" : "AAD_FREE"
  )
}

####################################################
# Cloud Applications Data Source (universal)
#     add the following well-known logical names
#     - All
#     - MicrosoftAdminPortals
#     - Office365
####################################################
data "msgraph_resource" "reference_cloud_applications" {
  url         = "servicePrincipals?$select=appId,displayName"
  api_version = "v1.0"
  response_export_values = {
    # JMSPath query to extract client id and displayName
    cloudApps = "value[].{appId:appId, displayName:displayName}"
  }
}

locals {
  reference_cloud_applications_well_known = [
    { appId = "All", displayName = "All" },
    { appId = "MicrosoftAdminPortals", displayName = "Microsoft Admin Portals" },
    { appId = "Office365", displayName = "Office 365" }
  ]

  reference_cloud_applications = distinct(concat(
    local.reference_cloud_applications_well_known,
    data.msgraph_resource.reference_cloud_applications.output.cloudApps
  ))
  reference_client_applications_well_known = [
    { appId = "ServicePrincipalsInMyTenant", displayName = "All" },
  ]
  reference_client_applications = distinct(concat(
    local.reference_client_applications_well_known,
    data.msgraph_resource.reference_cloud_applications.output.cloudApps
  ))
}

####################################################
# Named Locations Data Source (universal)
####################################################
data "msgraph_resource" "reference_named_locations" {
  url         = "identity/conditionalAccess/namedLocations?$select=id,displayName"
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

locals {
  reference_named_locations = data.msgraph_resource.reference_named_locations.output.namedLocations
}

####################################################
# Users Data Source (universal)
#     add the following well-known logical names
#     - None
#     - All
####################################################
data "msgraph_resource" "reference_users" {
  url         = "users?$select=id,displayName,mail,userPrincipalName"
  api_version = "v1.0"
  response_export_values = {
    # JMSPath query to extract id and displayName
    users = "value[].{id:id, displayName:displayName, mail:mail, userPrincipalName:userPrincipalName}"
  }
}

locals {
  reference_includeUsers = distinct(concat(
    [
      { id = "All", displayName = "All", mail = "", userPrincipalName = "" },
      { id = "None", displayName = "None", mail = "", userPrincipalName = "" }
    ],
    data.msgraph_resource.reference_users.output.users
  ))
  reference_excludeUsers = data.msgraph_resource.reference_users.output.users
}

####################################################
# Groups Data Source (universal)
####################################################
data "msgraph_resource" "reference_groups" {
  url         = "groups?$select=id,displayName,mail"
  api_version = "v1.0"
  response_export_values = {
    # JMSPath query to extract id and displayName
    groups = "value[].{id:id, displayName:displayName, mail:mail}"
  }
}

locals {
  reference_groups = data.msgraph_resource.reference_groups.output.groups
}

####################################################
# Directory Roles (universal)
#     this includes ONLY built-in
####################################################
data "msgraph_resource" "reference_directory_roles" {
  # url         = "directoryRoleTemplates"
  url         = "roleManagement/directory/roleDefinitions?$filter=isBuiltIn eq true&$select=id,displayName"
  api_version = "v1.0"
  response_export_values = {
    # JMSPath query to extract id and displayName
    roleDefinitions = "value[].{id:id, displayName:displayName}"
  }
}

locals {
  reference_directory_roles = data.msgraph_resource.reference_directory_roles.output.roleDefinitions
}
