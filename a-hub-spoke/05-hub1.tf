

locals {
  hub1_vpngw_bgp0  = azurerm_virtual_network_gateway.hub1_vpngw.bgp_settings[0].peering_addresses[0].default_addresses[0]
  hub1_vpngw_bgp1  = azurerm_virtual_network_gateway.hub1_vpngw.bgp_settings[0].peering_addresses[1].default_addresses[0]
  hub1_ars_bgp0    = tolist(azurerm_route_server.hub1_ars.virtual_router_ips)[0]
  hub1_ars_bgp1    = tolist(azurerm_route_server.hub1_ars.virtual_router_ips)[1]
  hub1_ars_bgp_asn = azurerm_route_server.hub1_ars.virtual_router_asn
  #hub1_dns_in_ip   = azurerm_private_dns_resolver_inbound_endpoint.hub1_dns_in
  #hub1_dns_out_ip  = azurerm_private_dns_resolver_inbound_endpoint.hub1_dns_out
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

  /*dynamic "delegation" {
    iterator = delegation
    for_each = each.value.delegate_dns ? [1] : []
    content {
      name = "Microsoft.Network.dnsResolvers"
      service_delegation {
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        name    = "Microsoft.Network/dnsResolvers"
      }
    }
  }*/
}

output "test" {
  value = { for k, v in local.hub1_subnets : k => v if v.delegate_dns }
}

# dns
#----------------------------

# link

resource "azurerm_private_dns_zone_virtual_network_link" "hub1_vnet_link" {
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = "${local.hub1_prefix}vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.azure.name
  virtual_network_id    = azurerm_virtual_network.hub1_vnet.id
  registration_enabled  = true
}

# resolver

resource "azurerm_private_dns_resolver" "hub1_dns_resolver" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}dns-resolver"
  location            = local.hub1_location
  virtual_network_id  = azurerm_virtual_network.hub1_vnet.id
}

# endpoint

/*resource "azurerm_private_dns_resolver_inbound_endpoint" "hub1_dns_in" {
  name                    = "${local.hub1_prefix}dns-in"
  private_dns_resolver_id = azurerm_private_dns_resolver.hub1_dns_resolver.id
  location                = local.hub1_location
  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = azurerm_subnet.hub1_subnets["${local.hub1_prefix}dns-in"].id
  }
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "hub1_dns_out" {
  name                    = "${local.hub1_prefix}dns-out"
  private_dns_resolver_id = azurerm_private_dns_resolver.hub1_dns_resolver.id
  location                = local.hub1_location
  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = azurerm_subnet.hub1_subnets["${local.hub1_prefix}dns-out"].id
  }
}*/

# vm
#----------------------------

module "hub1_vm" {
  source           = "../modules/ubuntu"
  resource_group   = azurerm_resource_group.rg.name
  name             = "${local.hub1_prefix}vm"
  location         = local.hub1_location
  subnet           = azurerm_subnet.hub1_subnets["${local.hub1_prefix}main"].id
  private_ip       = local.hub1_vm_addr
  storage_account  = azurerm_storage_account.region1
  admin_username   = local.username
  admin_password   = local.password
  custom_data      = base64encode(local.vm_startup)
  private_dns_zone = azurerm_private_dns_zone.azure.name
  private_dns_name = local.hub1_vm_dns_prefix
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

locals {
  hub1_vpngw_routes = {
    spoke2 = local.spoke2_address_space[0],
    spoke3 = local.spoke3_address_space[0],
  }
}

resource "azurerm_route" "hub1_vpngw_rt_routes" {
  for_each               = local.hub1_vpngw_routes
  resource_group_name    = azurerm_resource_group.rg.name
  name                   = "${local.hub1_prefix}vpngw-rt-${each.key}-route"
  route_table_name       = azurerm_route_table.hub1_vpngw_rt.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub1_nva_ilb_addr
}

# association

resource "azurerm_subnet_route_table_association" "hub1_vpngw_rt_spoke_route" {
  subnet_id      = azurerm_subnet.hub1_subnets["GatewaySubnet"].id
  route_table_id = azurerm_route_table.hub1_vpngw_rt.id
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
    subnet_id                     = azurerm_subnet.hub1_subnets["${local.hub1_prefix}ilb"].id
    private_ip_address            = local.hub1_nva_ilb_addr
    private_ip_address_allocation = "Static"
  }
}

# backend

resource "azurerm_lb_backend_address_pool" "hub1_nva" {
  name            = "${local.hub1_prefix}nva-beap"
  loadbalancer_id = azurerm_lb.hub1_nva_lb.id
}

resource "azurerm_lb_backend_address_pool_address" "hub1_nva" {
  name                    = "${local.hub1_prefix}nva-beap-addr"
  backend_address_pool_id = azurerm_lb_backend_address_pool.hub1_nva.id
  virtual_network_id      = azurerm_virtual_network.hub1_vnet.id
  ip_address              = local.hub1_nva_addr
}

# probe

resource "azurerm_lb_probe" "hub1_nva1_lb_probe" {
  name                = "${local.hub1_prefix}nva-probe"
  interval_in_seconds = 5
  number_of_probes    = 2
  loadbalancer_id     = azurerm_lb.hub1_nva_lb.id
  port                = 22
  protocol            = "Tcp"
}

# rule

resource "azurerm_lb_rule" "hub1_nva" {
  name     = "${local.hub1_prefix}nva-rule"
  protocol = "All"
  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.hub1_nva.id
  ]
  loadbalancer_id                = azurerm_lb.hub1_nva_lb.id
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "${local.hub1_prefix}nva-lb-feip"
  enable_floating_ip             = false
  idle_timeout_in_minutes        = 30
  load_distribution              = "Default"
  probe_id                       = azurerm_lb_probe.hub1_nva1_lb_probe.id
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
