
####################################################
# hub2
####################################################

# vnet peerings
#----------------------------

# spoke4-to-hub2 
# remote gw transit

resource "azurerm_virtual_network_peering" "spoke4_to_hub2_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-spoke4-to-hub2-peering"
  virtual_network_name         = azurerm_virtual_network.spoke4_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.hub2_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
  depends_on = [
    azurerm_virtual_network_gateway.hub2_vpngw
  ]
}

# spoke5-to-hub2

resource "azurerm_virtual_network_peering" "spoke5_to_hub2_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-spoke5-to-hub2-peering"
  virtual_network_name         = azurerm_virtual_network.spoke5_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.hub2_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# spoke6-to-hub2

resource "azurerm_virtual_network_peering" "spoke6_to_hub2_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-spoke6-to-hub2-peering"
  virtual_network_name         = azurerm_virtual_network.spoke6_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.hub2_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# hub2-to-spoke4 
# remote gw transit

resource "azurerm_virtual_network_peering" "hub2_to_spoke4_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub2-to-spoke4-peering"
  virtual_network_name         = azurerm_virtual_network.hub2_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke4_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on = [
    azurerm_virtual_network_gateway.hub2_vpngw
  ]
}

# hub2-to-spoke5

resource "azurerm_virtual_network_peering" "hub2_to_spoke5_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub2-to-spoke5-peering"
  virtual_network_name         = azurerm_virtual_network.hub2_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke5_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# hub2-to-spoke6

resource "azurerm_virtual_network_peering" "hub2_to_spoke6_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub2-to-spoke6-peering"
  virtual_network_name         = azurerm_virtual_network.hub2_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke6_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# local gw
#----------------------------

# branch3

resource "azurerm_local_network_gateway" "hub2_branch3_local_gw" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}branch3-local-gw"
  location            = local.hub2_location
  gateway_address     = azurerm_public_ip.branch3_nva_pip.ip_address
  address_space       = ["${local.branch3_nva_loopback0}/32", ]
  bgp_settings {
    asn                 = local.branch3_nva_asn
    bgp_peering_address = local.branch3_nva_loopback0
  }
}

# local gw connection
#----------------------------

# branch3

resource "azurerm_virtual_network_gateway_connection" "hub2_branch3_local_gw" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub2_prefix}branch3-local-gw-conn"
  location                   = local.hub2_location
  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.hub2_vpngw.id
  local_network_gateway_id   = azurerm_local_network_gateway.hub2_branch3_local_gw.id
  shared_key                 = local.psk
}

# nva
#----------------------------

# config

resource "local_file" "hub2_router" {
  content  = local.hub2_router_init
  filename = "_output/hub2-router.sh"
}

locals {
  hub2_router_init = templatefile("../scripts/nva-hub.sh", {
    LOCAL_ASN = local.hub2_nva_asn
    LOOPBACK0 = local.hub2_nva_loopback0
    INT_ADDR  = local.hub2_nva_addr
    VPN_PSK   = local.psk

    TUNNELS = [
      {
        ike = {
          name    = "Tunnel0"
          address = cidrhost(local.hub2_nva_tun_range0, 1)
          mask    = cidrnetmask(local.hub2_nva_tun_range0)
          source  = local.hub2_nva_addr
          dest    = local.hub1_nva_addr
        },
        ipsec = {
          peer_ip = local.hub1_nva_addr
          psk     = local.psk
        }
      },
    ]

    STATIC_ROUTES = [
      { network = "0.0.0.0", mask = "0.0.0.0", next_hop = local.hub2_default_gw_nva },
      { network = local.hub1_nva_loopback0, mask = "255.255.255.255", next_hop = "Tunnel0" },
      { network = local.hub1_nva_addr, mask = "255.255.255.255", next_hop = local.hub2_default_gw_nva },
      { network = local.hub2_ars_bgp0, mask = "255.255.255.255", next_hop = local.hub2_default_gw_nva },
      { network = local.hub2_ars_bgp1, mask = "255.255.255.255", next_hop = local.hub2_default_gw_nva },
      { network = cidrhost(local.spoke5_address_space[0], 0), mask = cidrnetmask(local.spoke5_address_space[0]), next_hop = local.hub2_default_gw_nva },
      { network = cidrhost(local.spoke6_address_space[0], 0), mask = cidrnetmask(local.spoke6_address_space[0]), next_hop = local.hub2_default_gw_nva },
    ]

    BGP_SESSIONS = [
      { peer_asn = local.hub2_ars_asn, peer_ip = local.hub2_ars_bgp0, as_override = true, ebgp_multihop = true },
      { peer_asn = local.hub2_ars_asn, peer_ip = local.hub2_ars_bgp1, as_override = true, ebgp_multihop = true },
      { peer_asn = local.hub1_nva_asn, peer_ip = local.hub1_nva_loopback0, next_hop_self = true, source_loopback = true },
    ]

    BGP_ADVERTISED_NETWORKS = [
      { network = cidrhost(local.spoke5_address_space[0], 0), mask = cidrnetmask(local.spoke5_address_space[0]) },
      { network = cidrhost(local.spoke6_address_space[0], 0), mask = cidrnetmask(local.spoke6_address_space[0]) },
    ]
  })
}

module "hub2_nva" {
  source               = "../modules/csr-hub"
  resource_group       = azurerm_resource_group.rg.name
  name                 = "${local.hub2_prefix}nva"
  location             = local.hub2_location
  enable_ip_forwarding = true
  enable_public_ip     = true
  subnet               = azurerm_subnet.hub2_subnets["${local.hub2_prefix}nva"].id
  private_ip           = local.hub2_nva_addr
  storage_account      = azurerm_storage_account.region2
  admin_username       = local.username
  admin_password       = local.password
  custom_data          = base64encode(local.hub2_router_init)
}

# udr (region2)
#----------------------------

# route table

resource "azurerm_route_table" "rt_region2" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.prefix}-rt-region2"
  location            = local.region2

  disable_bgp_route_propagation = true
  depends_on = [
    time_sleep.rt_spoke_region2,
  ]
}

# routes

resource "azurerm_route" "default_route_hub2" {
  name                   = "${local.prefix}-default-route-hub2"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.rt_region2.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.hub2_nva.interface.ip_configuration[0].private_ip_address
}

# association

resource "azurerm_subnet_route_table_association" "spoke5_default_route_hub2" {
  subnet_id      = azurerm_subnet.spoke5_subnets["${local.spoke5_prefix}main"].id
  route_table_id = azurerm_route_table.rt_region2.id
}

resource "azurerm_subnet_route_table_association" "spoke6_default_route_hub2" {
  subnet_id      = azurerm_subnet.spoke6_subnets["${local.spoke6_prefix}main"].id
  route_table_id = azurerm_route_table.rt_region2.id
}
