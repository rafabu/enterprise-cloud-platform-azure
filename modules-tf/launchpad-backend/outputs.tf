output "resource_group_launchpad" {
  description = "The ID of the launchpad (main) resource group"
  value = {
    id       = azapi_resource.launchpad_rg.id
    name     = azapi_resource.launchpad_rg.name
    location = azapi_resource.launchpad_rg.location
  }
}

output "resource_group_tf_backend" {
  description = "The ID of the backend resource group"
  value = {
    id       = azapi_resource.backend_rg.id
    name     = azapi_resource.backend_rg.name
    location = azapi_resource.backend_rg.location
  }
}

output "virtual_networks" {
  description = "core properties of virtual networks created"
  value = {
    for key, val in azurerm_virtual_network.lp : key => {
      id                  = val.id,
      name                = val.name,
      location            = val.location
      resource_group_name = val.resource_group_name
      address_space       = val.address_space
    }
  }
}

output "virtual_network_subnets" {
  description = "core properties of virtual networks subnets"
  value = {
    for key, val in azurerm_subnet.lp : key => {
      id                   = val.id,
      name                 = val.name,
      virtual_network_name = val.virtual_network_name
      resource_group_name  = val.resource_group_name
      address_prefixes     = val.address_prefixes
    }
  }
}

output "storage_accounts" {
  description = "Terraform backend storage accounts created for each ECP deployment level"
  value = {
    for key, val in azurerm_storage_account.backend : key => {
      subscription_id     = data.azurerm_client_config.this.subscription_id
      resource_group_name = val.resource_group_name
      id                  = val.id
      name                = val.name
      location            = val.location
      # include information required for private endpoint access without DNS
      private_endpoint_blob = {
        # fall back to default if custom DNS config is not present
        fqdn               = try(azurerm_private_endpoint.backend_blob[key].custom_dns_configs[0].fqdn, val.primary_blob_host)
        private_ip_address = try(azurerm_private_endpoint.backend_blob[key].private_service_connection[0].private_ip_address, "")
        subresource_names  = try(azurerm_private_endpoint.backend_blob[key].private_service_connection[0].subresource_names, ["blob"])
        subnet_id          = azurerm_private_endpoint.backend_blob[key].subnet_id
      }
      ecp_level            = key
      tf_backend_container = azapi_resource.tfstate_container[key].name

    }
  }
}

output "ecp_environment_name" {
  description = "Name of the ECP environment (used for naming resources)"
  value       = var.ecp_environment_name
}

output "ecp_azure_devops_automation_repository_name" {
  description = "Name of the ECP Azure DevOps automation repository"
  value       = var.ecp_azure_devops_automation_repository_name
}

output "ecp_azure_devops_configuration_repository_name" {
  description = "Name of the ECP Azure DevOps configuration repository"
  value       = var.ecp_azure_devops_configuration_repository_name
}

output "ecp_configuration_repo_deployment_root_path" {
  description = "Root path in ECP.Configuration repository where environment configurations are stored"
  value       = var.ecp_configuration_repo_deployment_root_path
}

output "azuredevops_organization_name" {
  description = "name of Azure DevOps organization"
  value       = var.ecp_azure_devops_organization_name
}

output "ecp_automation_terragrunt_version" {
  description = "Version of Terragrunt used for ECP automation"
  value       = var.ecp_automation_terragrunt_version
}

output "ecp_automation_terraform_version" {
  description = "Version of Terraform used for ECP automation"
  value       = var.ecp_automation_terraform_version
}

