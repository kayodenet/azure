

locals {
  hub2_vpngw_bgp0 = azurerm_virtual_network_gateway.hub2_vpngw.bgp_settings[0].peering_addresses[0].default_addresses[0]
  hub2_vpngw_bgp1 = azurerm_virtual_network_gateway.hub2_vpngw.bgp_settings[0].peering_addresses[1].default_addresses[0]
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
