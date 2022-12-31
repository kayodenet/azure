
# vnet
#----------------------------

resource "azurerm_virtual_network" "branch2_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch2_prefix}vnet"
  address_space       = local.branch2_address_space
  location            = local.branch2_location
}

# subnets
#----------------------------

resource "azurerm_subnet" "branch2_subnets" {
  for_each             = local.branch2_subnets
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.branch2_vnet.name
  name                 = each.key
  address_prefixes     = each.value.address_prefixes
}

resource "azurerm_subnet_network_security_group_association" "branch2_subnets" {
  subnet_id                 = azurerm_subnet.branch2_subnets["${local.branch2_prefix}main"].id
  network_security_group_id = azurerm_network_security_group.nsg_region1_main.id
}

# vm
#----------------------------

module "branch2_vm" {
  source          = "../../modules/ubuntu"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.branch2_prefix}vm"
  location        = local.branch2_location
  subnet          = azurerm_subnet.branch2_subnets["${local.branch2_prefix}main"].id
  private_ip      = local.branch2_vm_addr
  storage_account = azurerm_storage_account.region1
  admin_username  = local.username
  admin_password  = local.password
  custom_data     = base64encode(local.vm_startup)
}

# router
#----------------------------

# config

resource "local_file" "branch2_nva" {
  content  = local.branch2_nva_init
  filename = "_output/branch2-nva.sh"
}

locals {
  branch2_nva_init = templatefile("../../scripts/nva-branch.sh", {
    LOCAL_ASN = local.branch2_nva_asn
    LOOPBACK0 = local.branch2_nva_loopback0
    EXT_ADDR  = local.branch2_nva_ext_addr
    VPN_PSK   = local.psk

    TUNNELS = [
      {
        ike = {
          name    = "Tunnel0"
          address = cidrhost(local.branch2_nva_tun_range0, 1)
          mask    = cidrnetmask(local.branch2_nva_tun_range0)
          source  = local.branch2_nva_ext_addr
          dest    = azurerm_public_ip.bu2_vpngw_pip0.ip_address
        },
        ipsec = {
          peer_ip = azurerm_public_ip.bu2_vpngw_pip0.ip_address
          psk     = local.psk
        }
      },
      {
        ike = {
          name    = "Tunnel1"
          address = cidrhost(local.branch2_nva_tun_range1, 1)
          mask    = cidrnetmask(local.branch2_nva_tun_range1)
          source  = local.branch2_nva_ext_addr
          dest    = azurerm_public_ip.bu2_vpngw_pip1.ip_address
        },
        ipsec = {
          peer_ip = azurerm_public_ip.bu2_vpngw_pip1.ip_address
          psk     = local.psk
        }
      },
    ]

    STATIC_ROUTES = [
      { network = "0.0.0.0", mask = "0.0.0.0", next_hop = local.branch2_ext_default_gw },
      { network = local.bu2_vpngw_bgp0, mask = "255.255.255.255", next_hop = "Tunnel0" },
      { network = local.bu2_vpngw_bgp1, mask = "255.255.255.255", next_hop = "Tunnel1" },
      {
        network  = cidrhost(local.branch2_subnets["${local.branch2_prefix}main"].address_prefixes[0], 0)
        mask     = cidrnetmask(local.branch2_subnets["${local.branch2_prefix}main"].address_prefixes[0])
        next_hop = local.branch2_int_default_gw
      },
    ]

    BGP_SESSIONS = [
      { peer_asn = local.bu2_vpngw_asn, peer_ip = local.bu2_vpngw_bgp0, source_loopback = true, ebgp_multihop = true },
      { peer_asn = local.bu2_vpngw_asn, peer_ip = local.bu2_vpngw_bgp1, source_loopback = true, ebgp_multihop = true },
    ]

    BGP_ADVERTISED_NETWORKS = [
      {
        network = cidrhost(local.branch2_subnets["${local.branch2_prefix}main"].address_prefixes[0], 0)
        mask    = cidrnetmask(local.branch2_subnets["${local.branch2_prefix}main"].address_prefixes[0])
      },
    ]
  })
}

module "branch2_nva" {
  source               = "../../modules/csr-branch"
  resource_group       = azurerm_resource_group.rg.name
  name                 = "${local.branch2_prefix}nva"
  location             = local.branch2_location
  enable_ip_forwarding = true
  enable_public_ip     = true
  subnet_ext           = azurerm_subnet.branch2_subnets["${local.branch2_prefix}ext"].id
  subnet_int           = azurerm_subnet.branch2_subnets["${local.branch2_prefix}int"].id
  private_ip_ext       = local.branch2_nva_ext_addr
  private_ip_int       = local.branch2_nva_int_addr
  public_ip            = azurerm_public_ip.branch2_nva_pip.id
  storage_account      = azurerm_storage_account.region1
  admin_username       = local.username
  admin_password       = local.password
  custom_data          = base64encode(local.branch2_nva_init)
}

# udr
#----------------------------

resource "time_sleep" "rt_branch_region1" {
  create_duration = "180s"
  depends_on = [
    module.branch2_vm,
  ]
}

# route table

resource "azurerm_route_table" "branch2_rt" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch2_prefix}rt"
  location            = local.region1

  disable_bgp_route_propagation = true
  depends_on = [
    time_sleeptime_sleep.time_60,
  ]
}

# routes

resource "azurerm_route" "branch2_default_route_azure" {
  name                   = "${local.branch2_prefix}default-route-azure"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.branch2_rt.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.branch2_nva_int_addr
}

# association

resource "azurerm_subnet_route_table_association" "branch2_default_route_azure" {
  subnet_id      = azurerm_subnet.branch2_subnets["${local.branch2_prefix}main"].id
  route_table_id = azurerm_route_table.branch2_rt.id
}

