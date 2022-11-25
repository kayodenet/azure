
####################################################
# hub1
####################################################

# vnet peerings
#----------------------------

# spoke1-to-hub1
# using remote gw transit for this peering (nva bypass)

resource "azurerm_virtual_network_peering" "spoke1_to_hub1_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-spoke1-to-hub1-peering"
  virtual_network_name         = azurerm_virtual_network.spoke1_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.hub1_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
  depends_on = [
    azurerm_virtual_network_gateway.hub1_vpngw
  ]
}

# spoke2-to-hub1

resource "azurerm_virtual_network_peering" "spoke2_to_hub1_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-spoke2-to-hub1-peering"
  virtual_network_name         = azurerm_virtual_network.spoke2_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.hub1_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# spoke3-to-hub1

resource "azurerm_virtual_network_peering" "spoke3_to_hub1_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-spoke3-to-hub1-peering"
  virtual_network_name         = azurerm_virtual_network.spoke3_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.hub1_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# hub1-to-spoke1

resource "azurerm_virtual_network_peering" "hub1_to_spoke1_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub1-to-spoke1-peering"
  virtual_network_name         = azurerm_virtual_network.hub1_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke1_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on = [
    azurerm_virtual_network_gateway.hub1_vpngw
  ]
}

# hub1-to-spoke2

resource "azurerm_virtual_network_peering" "hub1_to_spoke2_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub1-to-spoke2-peering"
  virtual_network_name         = azurerm_virtual_network.hub1_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke2_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# hub1-to-spoke3

resource "azurerm_virtual_network_peering" "hub1_to_spoke3_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub1-to-spoke3-peering"
  virtual_network_name         = azurerm_virtual_network.hub1_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke3_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# local gw
#----------------------------

# branch1

resource "azurerm_local_network_gateway" "hub1_branch1_local_gw" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}branch1-local-gw"
  location            = local.hub1_location
  gateway_address     = azurerm_public_ip.branch1_nva_pip.ip_address
  address_space       = ["${local.branch1_nva_loopback0}/32", ]
  bgp_settings {
    asn                 = local.branch1_nva_asn
    bgp_peering_address = local.branch1_nva_loopback0
  }
}

# local gw connection
#----------------------------

# branch1

resource "azurerm_virtual_network_gateway_connection" "hub1_branch1_local_gw" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub1_prefix}branch1-local-gw-conn"
  location                   = local.hub1_location
  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.hub1_vpngw.id
  local_network_gateway_id   = azurerm_local_network_gateway.hub1_branch1_local_gw.id
  shared_key                 = local.psk
}

# nva
#----------------------------

# config

resource "local_file" "hub1_router" {
  content  = local.hub1_router_init
  filename = "_output/hub1-router.sh"
}

locals {
  hub1_router_route_map_name_nh = "NEXT-HOP"
  hub1_router_init = templatefile("../scripts/nva-hub.sh", {
    LOCAL_ASN = local.hub1_nva_asn
    LOOPBACK0 = local.hub1_nva_loopback0
    LOOPBACKS = {
      Loopback1 = local.hub1_nva_ilb_addr
    }
    INT_ADDR = local.hub1_nva_addr
    VPN_PSK  = local.psk

    ROUTE_MAPS = [
      {
        name   = local.hub1_router_route_map_name_nh
        action = "permit"
        rule   = 100
        commands = [
          "match ip address prefix-list all",
          "set ip next-hop ${local.hub1_nva_ilb_addr}"
        ]
      }
    ]

    TUNNELS = [
      {
        ike = {
          name    = "Tunnel0"
          address = cidrhost(local.hub1_nva_tun_range0, 1)
          mask    = cidrnetmask(local.hub1_nva_tun_range0)
          source  = local.hub1_nva_addr
          dest    = local.hub2_nva_addr
        },
        ipsec = {
          peer_ip = local.hub2_nva_addr
          psk     = local.psk
        }
      },
    ]

    STATIC_ROUTES = [
      { network = "0.0.0.0", mask = "0.0.0.0", next_hop = local.hub1_default_gw_nva },
      { network = local.hub2_nva_loopback0, mask = "255.255.255.255", next_hop = "Tunnel0" },
      { network = local.hub2_nva_addr, mask = "255.255.255.255", next_hop = local.hub1_default_gw_nva },
      { network = local.hub1_ars_bgp0, mask = "255.255.255.255", next_hop = local.hub1_default_gw_nva },
      { network = local.hub1_ars_bgp1, mask = "255.255.255.255", next_hop = local.hub1_default_gw_nva },
      { network = cidrhost(local.spoke2_address_space[0], 0), mask = cidrnetmask(local.spoke2_address_space[0]), next_hop = local.hub1_default_gw_nva },
      { network = cidrhost(local.spoke3_address_space[0], 0), mask = cidrnetmask(local.spoke3_address_space[0]), next_hop = local.hub1_default_gw_nva },
    ]

    BGP_SESSIONS = [
      {
        peer_asn      = local.hub1_ars_asn
        peer_ip       = local.hub1_ars_bgp0
        as_override   = true
        ebgp_multihop = true
        route_map = {
          name      = local.hub1_router_route_map_name_nh
          direction = "out"
        }
      },
      {
        peer_asn      = local.hub1_ars_asn
        peer_ip       = local.hub1_ars_bgp1
        as_override   = true
        ebgp_multihop = true
        route_map = { name = local.hub1_router_route_map_name_nh
          direction = "out"
        }
      },
      {
        peer_asn        = local.hub2_nva_asn
        peer_ip         = local.hub2_nva_loopback0
        next_hop_self   = true
        source_loopback = true
        route_map       = {}
      },
    ]

    BGP_ADVERTISED_NETWORKS = [
      { network = cidrhost(local.spoke2_address_space[0], 0), mask = cidrnetmask(local.spoke2_address_space[0]) },
      { network = cidrhost(local.spoke3_address_space[0], 0), mask = cidrnetmask(local.spoke3_address_space[0]) },
    ]
  })
}

module "hub1_nva" {
  source               = "../modules/csr-hub"
  resource_group       = azurerm_resource_group.rg.name
  name                 = "${local.hub1_prefix}nva"
  location             = local.hub1_location
  enable_ip_forwarding = true
  enable_public_ip     = true
  subnet               = azurerm_subnet.hub1_subnets["${local.hub1_prefix}nva"].id
  private_ip           = local.hub1_nva_addr
  storage_account      = azurerm_storage_account.region1
  admin_username       = local.username
  admin_password       = local.password
  custom_data          = base64encode(local.hub1_router_init)
}

# udr (region1)
#----------------------------

# route table

resource "azurerm_route_table" "rt_region1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.prefix}-rt-region1"
  location            = local.region1

  disable_bgp_route_propagation = true # NOTE: Required to allow Gw send traffic to NVA next hop
  depends_on = [
    time_sleep.rt_spoke_region1,
  ]
}

# routes

resource "azurerm_route" "default_route_hub1" {
  name                   = "${local.prefix}-default-route-hub1"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.rt_region1.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.hub1_nva.interface.ip_configuration[0].private_ip_address
}

# association

resource "azurerm_subnet_route_table_association" "spoke2_default_route_hub1" {
  subnet_id      = azurerm_subnet.spoke2_subnets["${local.spoke2_prefix}main"].id
  route_table_id = azurerm_route_table.rt_region1.id
  lifecycle {
    ignore_changes = all
  }
}

resource "azurerm_subnet_route_table_association" "spoke3_default_route_hub1" {
  subnet_id      = azurerm_subnet.spoke3_subnets["${local.spoke3_prefix}main"].id
  route_table_id = azurerm_route_table.rt_region1.id
  lifecycle {
    ignore_changes = all
  }
}
