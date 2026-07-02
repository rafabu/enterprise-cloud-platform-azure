locals {
  # subscription_id_management = var.ecp_management_subscription_id
  # resource_group_name        = data.azurecaf_name.rg.result

  # connectivity (Private DNS Zones)
  # subscription_id_connectivity     = var.ecp_connectivity_subscription_id != "00000000-0000-0000-0000-000000000000" ? var.ecp_connectivity_subscription_id : var.ecp_management_subscription_id
  # resource_group_name_connectivity = replace(local.resource_group_name, "-mgmt", "-conn")

  # resource_group_id = provider::azapi::subscription_resource_id(
  #   local.subscription_id_management,
  #   "Microsoft.Resources/resourceGroups",
  #   [
  #     local.resource_group_name
  #   ]
  # )

  resource_groups = {
    nwrg = {
      # Make sure to create this if you want to be able to cancel you subscription
      name     = "NetworkWatcherRG"
      location = var.azure_location
    }
    rg1 = {
      name     = "${data.azurecaf_name.rg.result}-spoke1"
      location = var.azure_location
    }
    rg2 = {
      name     = "${data.azurecaf_name.rg.result}-spoke2"
      location = var.azure_location
    }
  }

  subscription_display_name = "testing-stuff"

  network_security_groups = {
    nsg1 = {
      name     = "nsg-spoke1"
      resource_group_key = "rg1"
      location = var.azure_location
    }
  }
  virtual_networks = {
    vnet1 = {
      name               = "vnet-spoke1"
      resource_group_key = "rg1"
      address_space      = ["10.1.0.0/24"]
      location           = var.azure_location
      # vWAN connect
      vwan_connection_enabled = true
      vwan_hub_resource_id    = "/subscriptions/54a47b01-be16-4ac5-9c2c-a9847076d794/resourceGroups/iaih-d9-rg-ecpa-con-wan-szn/providers/Microsoft.Network/virtualHubs/iaih-d9-vhub-ecpa-con-szn-01"

      subnets = {
        subnet1 = {
          network_security_group = {
            key_reference = "nsg1"
          }
          name                                          = "number1"
          address_prefixes                              = ["10.1.0.0/27"]
          private_endpoint_network_policies_enabled     = false
          private_link_service_network_policies_enabled = false
          default_outbound_access_enabled               = false
          service_endpoints                             = []
          delegations                                   = []
        }
      }
    }
    # vnet2 = {
    #   name                    = "vnet-spoke2"
    #   resource_group_key      = "rg2"
    #   address_space           = ["10.2.0.0/16"]
    #   hub_network_resource_id = azurerm_virtual_network.hub.id
    # }
  }








}
