# module "virtual_network_side_car" {
#   source   = "Azure/avm-res-network-virtualnetwork/azurerm"
#   version  = var.avm-res-network-virtualnetwork_version #"0.19.0"
#   for_each = local.sidecar_virtual_networks

#   location             = each.value.location
#   parent_id            = each.value.parent_id
#   address_space        = each.value.address_space
#   ddos_protection_plan = each.value.ddos_protection_plan
#   enable_telemetry     = var.enable_telemetry
#   name                 = each.value.name
#   retry                = var.retry
#   subnets              = local.subnets[each.key]
#   tags                 = each.value.tags
#   timeouts             = var.timeouts
# }

# module "bastion_public_ip" {
#   source   = "Azure/avm-res-network-publicipaddress/azurerm"
#   version  = var.avm-res-network-publicipaddress_version # "0.2.1"
#   for_each = local.bastion_host_public_ips

#   location                = each.value.location
#   name                    = each.value.name
#   resource_group_name     = each.value.resource_group_name
#   allocation_method       = each.value.public_ip_settings.allocation_method
#   ddos_protection_mode    = each.value.public_ip_settings.ddos_protection_mode
#   ddos_protection_plan_id = each.value.public_ip_settings.ddos_protection_plan_id
#   domain_name_label       = each.value.public_ip_settings.domain_name_label
#   edge_zone               = each.value.public_ip_settings.edge_zone
#   enable_telemetry        = var.enable_telemetry
#   idle_timeout_in_minutes = each.value.public_ip_settings.idle_timeout_in_minutes
#   ip_tags                 = each.value.public_ip_settings.ip_tags
#   ip_version              = each.value.public_ip_settings.ip_version
#   public_ip_prefix_id     = each.value.public_ip_settings.public_ip_prefix_id
#   reverse_fqdn            = each.value.public_ip_settings.reverse_fqdn
#   sku                     = each.value.public_ip_settings.sku
#   sku_tier                = each.value.public_ip_settings.sku_tier
#   tags                    = each.value.tags
#   zones                   = each.value.zones
# }

# module "bastion_host" {
#   source   = "Azure/avm-res-network-bastionhost/azurerm"
#   version  = var.avm-res-network-bastionhost_version #"0.9.0"
#   for_each = local.bastion_hosts

#   location               = each.value.location
#   name                   = each.value.name
#   resource_group_name    = each.value.resource_group_name
#   copy_paste_enabled     = each.value.bastion_settings.copy_paste_enabled
#   enable_telemetry       = var.enable_telemetry
#   file_copy_enabled      = each.value.bastion_settings.file_copy_enabled
#   ip_configuration       = each.value.ip_configuration
#   ip_connect_enabled     = each.value.bastion_settings.ip_connect_enabled
#   kerberos_enabled       = each.value.bastion_settings.kerberos_enabled
#   scale_units            = each.value.bastion_settings.scale_units
#   shareable_link_enabled = each.value.bastion_settings.shareable_link_enabled
#   sku                    = each.value.bastion_settings.sku
#   tags                   = each.value.tags
#   tunneling_enabled      = each.value.bastion_settings.tunneling_enabled
#   zones                  = each.value.zones
# }