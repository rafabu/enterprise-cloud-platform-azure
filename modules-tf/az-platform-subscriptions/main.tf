module "launchpad_subscription" {
  for_each = toset(var.ecp_launchpad_subscription_id != "00000000-0000-0000-0000-000000000000" ? ["this"] : [])

  source = "../shared/az-subscription-basics"

  subscription_id   = var.ecp_launchpad_subscription_id
  subscription_name = "${replace(data.azurecaf_name.rg.result, "-rg-", "-sub-")}-launchpad"
  tags = merge(
    var.azure_tags,
    var.launchpad_azure_tags
  )
  read_only_tags = [
    "businessUnit",
    "costCenter",
    "dataClassification",
    "workloadEnvironment",
    "workloadName",
    "workloadOwner"
  ]
  region = var.azure_location
}

module "management_subscription" {
  for_each = toset(var.ecp_management_subscription_id != "00000000-0000-0000-0000-000000000000" ? ["this"] : [])

  source = "../shared/az-subscription-basics"

  subscription_id   = var.ecp_management_subscription_id
  subscription_name = "${replace(data.azurecaf_name.rg.result, "-rg-", "-sub-")}-management"
  tags              = merge(
    var.azure_tags,
    var.management_azure_tags
  )
  read_only_tags = [
    "businessUnit",
    "costCenter",
    "dataClassification",
    "workloadEnvironment",
    "workloadName",
    "workloadOwner"
  ]
  region = var.azure_location
}

module "network_subscription" {
  for_each = toset(var.ecp_network_subscription_id != "00000000-0000-0000-0000-000000000000" ? ["this"] : [])

  source = "../shared/az-subscription-basics"

  subscription_id   = var.ecp_network_subscription_id
  subscription_name = "${replace(data.azurecaf_name.rg.result, "-rg-", "-sub-")}-network"
  tags              = merge(
    var.azure_tags,
    var.network_azure_tags
  )
  read_only_tags = [
    "businessUnit",
    "costCenter",
    "dataClassification",
    "workloadEnvironment",
    "workloadName",
    "workloadOwner"
  ]
  region = var.azure_location
}

module "identity_subscription" {
  for_each = toset(var.ecp_identity_subscription_id != "00000000-0000-0000-0000-000000000000" ? ["this"] : [])

  source = "../shared/az-subscription-basics"

  subscription_id   = var.ecp_identity_subscription_id
  subscription_name = "${replace(data.azurecaf_name.rg.result, "-rg-", "-sub-")}-identity"
  tags              = merge(
    var.azure_tags,
    var.identity_azure_tags
  )
  read_only_tags = [
    "businessUnit",
    "costCenter",
    "dataClassification",
    "workloadEnvironment",
    "workloadName",
    "workloadOwner"
  ]
  region = var.azure_location
}

module "security_subscription" {
  for_each = toset(var.ecp_security_subscription_id != "00000000-0000-0000-0000-000000000000" ? ["this"] : [])

  source = "../shared/az-subscription-basics"

  subscription_id   = var.ecp_security_subscription_id
  subscription_name = "${replace(data.azurecaf_name.rg.result, "-rg-", "-sub-")}-security"
  tags              = merge(
    var.azure_tags,
    var.security_azure_tags
  )
  read_only_tags = [
    "businessUnit",
    "costCenter",
    "dataClassification",
    "workloadEnvironment",
    "workloadName",
    "workloadOwner"
  ]
  region = var.azure_location
}
