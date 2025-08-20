# # # locals {
# # #   policy_identitySecurityDefaultsEnforcement_enabled = false
# # #   policy_identitySecurityDefaultsEnforcement_body_create = jsonencode(
# # #     {
# # #       isEnabled = local.policy_identitySecurityDefaultsEnforcement_enabled
# # #     }
# # #   )
# # #   policy_identitySecurityDefaultsEnforcement_body_destroy = jsonencode(
# # #     {
# # #       isEnabled = "true"
# # #     }
# # #   )
# # # }

# # # resource "terraform_data" "policy_identity_security_defaults_enforcement_update" {
# # #   triggers_replace = [
# # #     local.policy_identitySecurityDefaultsEnforcement_enabled
# # #   ]

# # #   provisioner "local-exec" {
# # #     when        = create
# # #     interpreter = ["pwsh", "-NoLogo", "-NonInteractive", "-ExecutionPolicy", "RemoteSigned", "-command"]
# # #     command     = <<-SCRIPT
# # #       az rest --method patch --url 'https://graph.microsoft.com/v1.0/policies/identitySecurityDefaultsEnforcementPolicy' --body '${local.policy_identitySecurityDefaultsEnforcement_body_create}' --headers 'Content-Type=application/json'
# # #     SCRIPT
# # #   }

# # #   provisioner "local-exec" {
# # #     # re-enable security defaults on destroy
# # #     when        = destroy
# # #     interpreter = ["pwsh", "-NoLogo", "-NonInteractive", "-ExecutionPolicy", "RemoteSigned", "-command"]
# # #     command = <<-SCRIPT
# # #       az rest --method patch --url 'https://graph.microsoft.com/v1.0/policies/identitySecurityDefaultsEnforcementPolicy' --body '${jsonencode(
# # #     {
# # #       isEnabled = "true"
# # #     }
# # # )}' --headers 'Content-Type=application/json'
# # #     SCRIPT
# # # }
# # # }

# # # # authentication requirements:
# # # #     Policy.Read.All / 572fea84-0151-49b2-9301-11cb16974376 or
# # # #     Policy.ReadWrite.SecurityDefaults / Policy.ReadWrite.SecurityDefaults

# # # #     NOTE: Scopes must already have been granted to service principal, executing the terraform code.

# # # # requires a PATCH operation - hence not yet supported
# # # #
# # # #     maybe a future msgraph_update_resource resource will come  to help (msgraph_resource does POST)
# # # #
# # # #  resource "msgraph_update_resource" "policy_identity_security_defaults_enforcement_update" {
# # # #   url         = "policies/identitySecurityDefaultsEnforcementPolicy"
# # # #   api_version = "v1.0"
# # # #    body = {
# # # #      isEnabled = local.policy_identitySecurityDefaultsEnforcement_body_create
# # # #     }
# # # #    response_export_values = {
# # # #      all    = "@"
# # # #    }
# # # #  }

# # # data "msgraph_resource" "policy_identity_security_defaults_enforcement" {
# # #   url         = "policies/identitySecurityDefaultsEnforcementPolicy"
# # #   api_version = "v1.0"
# # #   response_export_values = {
# # #     all = "@"
# # #   }

# # #   depends_on = [
# # #     terraform_data.policy_identity_security_defaults_enforcement_update,
# # #     # msgraph_update_resource.policy_identity_security_defaults_enforcement_update
# # #   ]

# # # }

# # # output "policy_identity_security_defaults_enforcement" {
# # #   value = data.msgraph_resource.policy_identity_security_defaults_enforcement.output.all.isEnabled
# # # }
