# while bootstrapping, we most likely need a temporary NAT gateway, to allow outbound access.action" "name" {
locals {
  # require NAT gateway if outbound access is not enabled on the subnet &&
  #     no routing infrastructure is present yet (e.g. firewall with SNAT)
  #     --> var.virtual_network_island_mode == false
  mpool_nat_gateway_subnet_links = {
    for s in var.subnet_artefact_names : s => {
      # TODO: enhance logic to detect existing routing infra that already provides outbound access
      nat_gateway_link = try(var.virtual_network_subnet_definitions[s.key].defaultOutboundAccess, false) == false ? true : false
    }
  }
  mpool_nat_gateway_deploy = var.virtual_network_island_mode && anytrue([
    for s in local.mpool_nat_gateway_subnet_links : true if s.nat_gateway_link == true
  ])
}

resource "azurerm_public_ip" "mpool" {
  provider = azurerm.launchpad

  for_each = toset(local.mpool_nat_gateway_deploy ? ["do"] : [])

  name                = "${replace(data.azurecaf_name.rg.result, "-rg-", "-ng-")}-pip-01"
  location            = azurerm_resource_group.mpool.location
  resource_group_name = azurerm_resource_group.mpool.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = null
}

resource "azurerm_nat_gateway" "mpool" {
  provider = azurerm.launchpad

  for_each = toset(local.mpool_nat_gateway_deploy ? ["do"] : [])

  name                = replace(data.azurecaf_name.rg.result, "-rg-", "-ng-")
  location            = azurerm_resource_group.mpool.location
  resource_group_name = azurerm_resource_group.mpool.name
  sku_name            = "Standard"
  zones               = null
}

resource "azurerm_nat_gateway_public_ip_association" "mpool" {
  provider = azurerm.launchpad

  for_each = toset(local.mpool_nat_gateway_deploy ? ["do"] : [])

  nat_gateway_id       = azurerm_nat_gateway.mpool[each.key].id
  public_ip_address_id = azurerm_public_ip.mpool[each.key].id
}

resource "azurerm_subnet_nat_gateway_association" "mpool" {
  provider = azurerm.launchpad

  for_each = local.mpool_nat_gateway_deploy ? toset([
    for key, attr in local.mpool_nat_gateway_subnet_links : key
    if attr.nat_gateway_link == true
  ]) : toset([])

  subnet_id      = azurerm_subnet.mpool[each.key].id
  nat_gateway_id = azurerm_nat_gateway.mpool["do"].id
}
