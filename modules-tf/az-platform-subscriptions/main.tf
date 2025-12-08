module "launchpad_subscription" {
  source = "../shared/az-subscription-basics"

  subscription_id   = "e1b3be0d-0df0-4e0a-a585-ffc97f60bd42"
  subscription_name = "rabu-d7-sub-ecpa-launchpad"
  tags = var.azure_tags
  read_only_tags = [
    "businessUnit",
    "workloadName"
  ]
}
