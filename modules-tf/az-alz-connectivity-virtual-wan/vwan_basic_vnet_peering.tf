module "vwan_basic_vnet_launchpad_peering_helper" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm//modules/peering"
  version = "~> 0.17"

  # peering to allow con-mgmt vnet access for ADO agents is only required if
  #     vwan is running on BASIC SKU (no inter-hub routing)
  for_each = toset(try(local.virtual_wan_object.type, "Standard") == "Basic" ? ["this"] : [])

  name         = "rabu-d7-vnet-ecpa-con-mgmt-szn-peering-due-to-basic-vwan-sku"
  reverse_name = "rabu-d7-vnet-ecpalp-main-peering-peering-due-to-basic-vwan-sku"

  parent_id                 = "/subscriptions/e1b3be0d-0df0-4e0a-a585-ffc97f60bd42/resourceGroups/rabu-d7-rg-ecpalp-main/providers/Microsoft.Network/virtualNetworks/rabu-d7-vnet-ecpalp-main"
  remote_virtual_network_id = "/subscriptions/2ad5a985-e423-4a91-aea0-248c51b2e1cc/resourceGroups/rabu-d7-rg-ecpa-con-mgmt/providers/Microsoft.Network/virtualNetworks/rabu-d7-vnet-ecpa-con-mgmt-szn"

  create_reverse_peering = true

  # only allow vnet access from ecpalp to con-mgm, but not the other way around
  allow_forwarded_traffic              = false
  reverse_allow_forwarded_traffic      = false
  allow_gateway_transit                = false
  reverse_allow_gateway_transit        = false
  allow_virtual_network_access         = true
  reverse_allow_virtual_network_access = false # no access from con-mgm to ecpalp
  use_remote_gateways                  = false
  reverse_use_remote_gateways          = false
  peer_complete_vnets                  = true
  reverse_peer_complete_vnets          = true
}
