

locals {
  hub2_vpngw_bgp0  = azurerm_virtual_network_gateway.hub2_vpngw.bgp_settings[0].peering_addresses[0].default_addresses[0]
  hub2_vpngw_bgp1  = azurerm_virtual_network_gateway.hub2_vpngw.bgp_settings[0].peering_addresses[1].default_addresses[0]
  hub2_ars_bgp0    = tolist(azurerm_route_server.hub2_ars.virtual_router_ips)[0]
  hub2_ars_bgp1    = tolist(azurerm_route_server.hub2_ars.virtual_router_ips)[1]
  hub2_ars_bgp_asn = azurerm_route_server.hub2_ars.virtual_router_asn
}

# vnet
#----------------------------

resource "azurerm_virtual_network" "hub2_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}vnet"
  address_space       = local.hub2_address_space
  location            = local.hub2_location
}

# subnets
#----------------------------

resource "azurerm_subnet" "hub2_subnets" {
  for_each             = local.hub2_subnets
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub2_vnet.name
  name                 = each.key
  address_prefixes     = each.value.address_prefixes
}

# vm
#----------------------------

module "hub2_vm" {
  source          = "../modules/ubuntu"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.hub2_prefix}vm"
  location        = local.hub2_location
  subnet          = azurerm_subnet.hub2_subnets["${local.hub2_prefix}main"].id
  private_ip      = local.hub2_vm_addr
  storage_account = azurerm_storage_account.region2
  admin_username  = local.username
  admin_password  = local.password
  custom_data     = base64encode(local.vm_startup)
}

# route server
#----------------------------

resource "azurerm_route_server" "hub2_ars" {
  resource_group_name              = azurerm_resource_group.rg.name
  name                             = "${local.hub2_prefix}ars"
  location                         = local.hub2_location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.hub2_ars_pip.id
  subnet_id                        = azurerm_subnet.hub2_subnets["RouteServerSubnet"].id
  branch_to_branch_traffic_enabled = true
}

resource "azurerm_route_server_bgp_connection" "hub2_nva" {
  name            = "${local.hub2_prefix}nva"
  route_server_id = azurerm_route_server.hub2_ars.id
  peer_asn        = local.hub2_nva_asn
  peer_ip         = local.hub2_nva_addr
}

# vpngw
#----------------------------

resource "azurerm_virtual_network_gateway" "hub2_vpngw" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}vpngw"
  location            = local.hub2_location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw3"
  enable_bgp          = true
  active_active       = true
  ip_configuration {
    name                          = "${local.hub2_prefix}link-0"
    subnet_id                     = azurerm_subnet.hub2_subnets["GatewaySubnet"].id
    public_ip_address_id          = azurerm_public_ip.hub2_vpngw_pip0.id
    private_ip_address_allocation = "Dynamic"
  }
  ip_configuration {
    name                          = "${local.hub2_prefix}link-1"
    subnet_id                     = azurerm_subnet.hub2_subnets["GatewaySubnet"].id
    public_ip_address_id          = azurerm_public_ip.hub2_vpngw_pip1.id
    private_ip_address_allocation = "Dynamic"
  }
  bgp_settings {
    asn = local.hub2_vpngw_asn
    peering_addresses {
      ip_configuration_name = "${local.hub2_prefix}link-0"
      apipa_addresses       = [local.hub2_vpngw_bgp_apipa_0, ]
    }
    peering_addresses {
      ip_configuration_name = "${local.hub2_prefix}link-1"
      apipa_addresses       = [local.hub2_vpngw_bgp_apipa_0, ]
    }
  }
}

# udr
#----------------------------

# route table

resource "azurerm_route_table" "hub2_vpngw_rt" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}vpngw-rt"
  location            = local.region2

  disable_bgp_route_propagation = false
}

# routes

locals {
  hub2_vpngw_routes = {
    spoke5 = local.spoke5_address_space[0],
    spoke6 = local.spoke6_address_space[0],
  }
}

resource "azurerm_route" "hub2_vpngw_rt_routes" {
  for_each               = local.hub2_vpngw_routes
  resource_group_name    = azurerm_resource_group.rg.name
  name                   = "${local.hub2_prefix}vpngw-rt-${each.key}-route"
  route_table_name       = azurerm_route_table.hub2_vpngw_rt.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_nva_ilb_addr
}

# association

resource "azurerm_subnet_route_table_association" "hub2_vpngw_rt_spoke_route" {
  subnet_id      = azurerm_subnet.hub2_subnets["GatewaySubnet"].id
  route_table_id = azurerm_route_table.hub2_vpngw_rt.id
}

# internal lb
#----------------------------

resource "azurerm_lb" "hub2_nva_lb" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}nva-lb"
  location            = local.hub2_location
  sku                 = "Standard"
  frontend_ip_configuration {
    name                          = "${local.hub2_prefix}nva-lb-feip"
    subnet_id                     = azurerm_subnet.hub2_subnets["${local.hub2_prefix}ilb"].id
    private_ip_address            = local.hub2_nva_ilb_addr
    private_ip_address_allocation = "Static"
  }
}

# backend

resource "azurerm_lb_backend_address_pool" "hub2_nva" {
  name            = "${local.hub2_prefix}nva-beap"
  loadbalancer_id = azurerm_lb.hub2_nva_lb.id
}

resource "azurerm_lb_backend_address_pool_address" "hub2_nva" {
  name                    = "${local.hub2_prefix}nva-beap-addr"
  backend_address_pool_id = azurerm_lb_backend_address_pool.hub2_nva.id
  virtual_network_id      = azurerm_virtual_network.hub2_vnet.id
  ip_address              = local.hub2_nva_addr
}

# probe

resource "azurerm_lb_probe" "hub2_nva1_lb_probe" {
  name                = "${local.hub2_prefix}nva-probe"
  interval_in_seconds = 5
  number_of_probes    = 2
  loadbalancer_id     = azurerm_lb.hub2_nva_lb.id
  port                = 22
  protocol            = "Tcp"
}

# rule

resource "azurerm_lb_rule" "hub2_nva" {
  name     = "${local.hub2_prefix}nva-rule"
  protocol = "All"
  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.hub2_nva.id
  ]
  loadbalancer_id                = azurerm_lb.hub2_nva_lb.id
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "${local.hub2_prefix}nva-lb-feip"
  enable_floating_ip             = false
  idle_timeout_in_minutes        = 30
  load_distribution              = "Default"
  probe_id                       = azurerm_lb_probe.hub2_nva1_lb_probe.id
}

