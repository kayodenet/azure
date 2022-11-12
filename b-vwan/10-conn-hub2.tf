
####################################################
# hub2
####################################################

# vnet peerings
#----------------------------

# spoke5-to-hub2

resource "azurerm_virtual_network_peering" "spoke5_to_hub2_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-spoke5-to-hub2-peering"
  virtual_network_name         = azurerm_virtual_network.spoke5_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.hub2_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true

}

# spoke6-to-hub2

resource "azurerm_virtual_network_peering" "spoke6_to_hub2_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-spoke6-to-hub2-peering"
  virtual_network_name         = azurerm_virtual_network.spoke6_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.hub2_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
}

# hub2-to-spoke5

resource "azurerm_virtual_network_peering" "hub2_to_spoke5_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub2-to-spoke5-peering"
  virtual_network_name         = azurerm_virtual_network.hub2_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke5_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}

# hub2-to-spoke6

resource "azurerm_virtual_network_peering" "hub2_to_spoke6_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub2-to-spoke6-peering"
  virtual_network_name         = azurerm_virtual_network.hub2_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke6_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}

# local gw
#----------------------------

# vhub2

resource "azurerm_local_network_gateway" "hub2_vhub2_local_gw0" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}vhub2-local-gw0"
  location            = local.hub2_location
  gateway_address     = local.vhub2_vpngw_pip0
  address_space       = ["${local.vhub2_vpngw_bgp0}/32", ]
  bgp_settings {
    asn                 = local.vhub2_bgp_asn
    bgp_peering_address = local.vhub2_vpngw_bgp0
  }
}

resource "azurerm_local_network_gateway" "hub2_vhub2_local_gw1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}vhub2-local-gw1"
  location            = local.hub2_location
  gateway_address     = local.vhub2_vpngw_pip1
  address_space       = ["${local.vhub2_vpngw_bgp1}/32", ]
  bgp_settings {
    asn                 = local.vhub2_bgp_asn
    bgp_peering_address = local.vhub2_vpngw_bgp1
  }
}

# local gw connection
#----------------------------

# vhub2

resource "azurerm_virtual_network_gateway_connection" "hub2_vhub2_local_gw0" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub2_prefix}vhub2-local-gw0"
  location                   = local.hub2_location
  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.hub2_vpngw.id
  local_network_gateway_id   = azurerm_local_network_gateway.hub2_vhub2_local_gw0.id
  shared_key                 = local.psk
}

resource "azurerm_virtual_network_gateway_connection" "hub2_vhub2_local_gw1" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub2_prefix}vhub2-local-gw1"
  location                   = local.hub2_location
  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.hub2_vpngw.id
  local_network_gateway_id   = azurerm_local_network_gateway.hub2_vhub2_local_gw1.id
  shared_key                 = local.psk
}

####################################################
# vhub2
####################################################

# vpn-site connections
#----------------------------

# branch3

resource "azurerm_vpn_gateway_connection" "vhub2_site_branch3_conn" {
  name                      = "${local.vhub2_prefix}site-branch3-conn"
  vpn_gateway_id            = azurerm_vpn_gateway.vhub2.id
  remote_vpn_site_id        = azurerm_vpn_site.vhub2_site_branch3.id
  internet_security_enabled = false
  vpn_link {
    name             = "${local.vhub2_prefix}site-branch3-conn-vpn-link-0"
    bgp_enabled      = true
    shared_key       = local.psk
    vpn_site_link_id = azurerm_vpn_site.vhub2_site_branch3.link[0].id
  }
}

# hub2

resource "azurerm_vpn_gateway_connection" "vhub2_site_hub2_conn" {
  name                      = "${local.vhub2_prefix}site-hub2-conn"
  vpn_gateway_id            = azurerm_vpn_gateway.vhub2.id
  remote_vpn_site_id        = azurerm_vpn_site.vhub2_site_hub2.id
  internet_security_enabled = false
  vpn_link {
    name             = "${local.vhub2_prefix}site-hub2-conn-vpn-link-0"
    bgp_enabled      = true
    shared_key       = local.psk
    vpn_site_link_id = azurerm_vpn_site.vhub2_site_hub2.link[0].id
  }
  vpn_link {
    name             = "${local.vhub2_prefix}site-hub2-conn-vpn-link-1"
    bgp_enabled      = true
    shared_key       = local.psk
    vpn_site_link_id = azurerm_vpn_site.vhub2_site_hub2.link[1].id
  }
}

# vnet connections
#----------------------------

resource "azurerm_virtual_hub_connection" "spoke4_vnet_conn" {
  name                      = "${local.vhub2_prefix}spoke4-vnet-conn"
  virtual_hub_id            = azurerm_virtual_hub.vhub2.id
  remote_virtual_network_id = azurerm_virtual_network.spoke4_vnet.id
}


