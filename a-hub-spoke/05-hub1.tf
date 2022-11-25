

locals {
  hub1_vpngw_bgp0  = azurerm_virtual_network_gateway.hub1_vpngw.bgp_settings[0].peering_addresses[0].default_addresses[0]
  hub1_vpngw_bgp1  = azurerm_virtual_network_gateway.hub1_vpngw.bgp_settings[0].peering_addresses[1].default_addresses[0]
  hub1_ars_bgp0    = tolist(azurerm_route_server.hub1_ars.virtual_router_ips)[0]
  hub1_ars_bgp1    = tolist(azurerm_route_server.hub1_ars.virtual_router_ips)[1]
  hub1_ars_bgp_asn = azurerm_route_server.hub1_ars.virtual_router_asn
}

# vnet
#----------------------------

resource "azurerm_virtual_network" "hub1_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}vnet"
  address_space       = local.hub1_address_space
  location            = local.hub1_location
}

# subnets
#----------------------------

resource "azurerm_subnet" "hub1_subnets" {
  for_each             = local.hub1_subnets
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub1_vnet.name
  name                 = each.key
  address_prefixes     = each.value.address_prefixes
}
# vm
#----------------------------

module "hub1_vm" {
  source          = "../modules/ubuntu"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.hub1_prefix}vm"
  location        = local.hub1_location
  subnet          = azurerm_subnet.hub1_subnets["${local.hub1_prefix}main"].id
  private_ip      = local.hub1_vm_addr
  storage_account = azurerm_storage_account.region1
  admin_username  = local.username
  admin_password  = local.password
  custom_data     = base64encode(local.vm_startup)
}

# route server
#----------------------------

resource "azurerm_route_server" "hub1_ars" {
  resource_group_name              = azurerm_resource_group.rg.name
  name                             = "${local.hub1_prefix}ars"
  location                         = local.hub1_location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.hub1_ars_pip.id
  subnet_id                        = azurerm_subnet.hub1_subnets["RouteServerSubnet"].id
  branch_to_branch_traffic_enabled = true
}

resource "azurerm_route_server_bgp_connection" "hub1_nva" {
  name            = "${local.hub1_prefix}nva"
  route_server_id = azurerm_route_server.hub1_ars.id
  peer_asn        = local.hub1_nva_asn
  peer_ip         = local.hub1_nva_addr
}

# vpngw
#----------------------------

resource "azurerm_virtual_network_gateway" "hub1_vpngw" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}vpngw"
  location            = local.hub1_location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw3"
  enable_bgp          = true
  active_active       = true
  ip_configuration {
    name                          = "${local.hub1_prefix}link-0"
    subnet_id                     = azurerm_subnet.hub1_subnets["GatewaySubnet"].id
    public_ip_address_id          = azurerm_public_ip.hub1_vpngw_pip0.id
    private_ip_address_allocation = "Dynamic"
  }
  ip_configuration {
    name                          = "${local.hub1_prefix}link-1"
    subnet_id                     = azurerm_subnet.hub1_subnets["GatewaySubnet"].id
    public_ip_address_id          = azurerm_public_ip.hub1_vpngw_pip1.id
    private_ip_address_allocation = "Dynamic"
  }
  bgp_settings {
    asn = local.hub1_vpngw_asn
    peering_addresses {
      ip_configuration_name = "${local.hub1_prefix}link-0"
      apipa_addresses       = [local.hub1_vpngw_bgp_apipa_0, ]
    }
    peering_addresses {
      ip_configuration_name = "${local.hub1_prefix}link-1"
      apipa_addresses       = [local.hub1_vpngw_bgp_apipa_0, ]
    }
  }
}

# udr
#----------------------------

# route table

resource "azurerm_route_table" "hub1_vpngw_rt" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}vpngw-rt"
  location            = local.region1

  disable_bgp_route_propagation = false
}

# routes

resource "azurerm_route" "hub1_vpngw_rt_spoke2_route" {
  name                   = "${local.hub1_prefix}vpngw-rt-spoke2-route"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.hub1_vpngw_rt.name
  address_prefix         = local.spoke2_address_space[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub1_nva_addr
}

resource "azurerm_route" "hub1_vpngw_rt_spoke3_route" {
  name                   = "${local.hub1_prefix}vpngw-rt-spoke3-route"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.hub1_vpngw_rt.name
  address_prefix         = local.spoke3_address_space[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub1_nva_addr
}


# association

resource "azurerm_subnet_route_table_association" "hub1_vpngw_rt_spoke2_route" {
  subnet_id      = azurerm_subnet.hub1_subnets["GatewaySubnet"].id
  route_table_id = azurerm_route_table.hub1_vpngw_rt.id
}

# ergw
#----------------------------

resource "azurerm_virtual_network_gateway" "hub1_ergw" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}ergw"
  location            = local.hub1_location
  type                = "ExpressRoute"
  vpn_type            = "RouteBased"
  sku                 = "Standard"
  enable_bgp          = true
  active_active       = false
  ip_configuration {
    name                          = "${local.hub1_prefix}link-0"
    subnet_id                     = azurerm_subnet.hub1_subnets["GatewaySubnet"].id
    public_ip_address_id          = azurerm_public_ip.hub1_ergw_pip.id
    private_ip_address_allocation = "Dynamic"
  }
}

# internal lb
#----------------------------

resource "azurerm_lb" "hub1_nva_lb" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}nva-lb"
  location            = local.hub1_location
  sku                 = "Standard"
  frontend_ip_configuration {
    name                          = "${local.hub1_prefix}nva-lb-feip"
    subnet_id                     = azurerm_subnet.hub1_subnets["${local.hub1_prefix}nva"].id
    private_ip_address            = local.hub1_nva_lb_addr
    private_ip_address_allocation = "Static"
  }
}
