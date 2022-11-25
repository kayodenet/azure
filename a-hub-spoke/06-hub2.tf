

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

resource "azurerm_route" "hub2_vpngw_rt_spoke5_route" {
  name                   = "${local.hub2_prefix}vpngw-rt-spoke5-route"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.hub2_vpngw_rt.name
  address_prefix         = local.spoke5_address_space[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_nva_addr
}

resource "azurerm_route" "hub2_vpngw_rt_spoke6_route" {
  name                   = "${local.hub2_prefix}vpngw-rt-spoke6-route"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.hub2_vpngw_rt.name
  address_prefix         = local.spoke6_address_space[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_nva_addr
}


# association

resource "azurerm_subnet_route_table_association" "hub2_vpngw_rt_spoke5_route" {
  subnet_id      = azurerm_subnet.hub2_subnets["GatewaySubnet"].id
  route_table_id = azurerm_route_table.hub2_vpngw_rt.id
}


