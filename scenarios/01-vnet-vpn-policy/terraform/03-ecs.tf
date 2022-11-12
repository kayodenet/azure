
# vnet
#----------------------------

resource "azurerm_virtual_network" "ecs_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.ecs_prefix}vnet"
  address_space       = local.ecs_address_space
  location            = local.ecs_location
}

# subnets
#----------------------------

resource "azurerm_subnet" "ecs_subnets" {
  for_each             = local.ecs_subnets
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.ecs_vnet.name
  name                 = each.key
  address_prefixes     = each.value.address_prefixes
}

# vm
#----------------------------

module "ecs_main_vm" {
  source          = "../../../modules/ubuntu"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.ecs_prefix}main-vm"
  location        = local.ecs_location
  subnet          = azurerm_subnet.ecs_subnets["${local.ecs_prefix}main"].id
  private_ip      = local.ecs_main_vm_addr
  storage_account = azurerm_storage_account.region1
  admin_username  = local.username
  admin_password  = local.password
  custom_data     = base64encode(local.vm_startup)
}

module "ecs_bu1_vm" {
  source          = "../../../modules/ubuntu"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.ecs_prefix}bu1-vm"
  location        = local.ecs_location
  subnet          = azurerm_subnet.ecs_subnets["${local.ecs_prefix}bu1"].id
  private_ip      = local.ecs_bu1_vm_addr
  storage_account = azurerm_storage_account.region1
  admin_username  = local.username
  admin_password  = local.password
  custom_data     = base64encode(local.vm_startup)
}

module "ecs_bu2_vm" {
  source          = "../../../modules/ubuntu"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.ecs_prefix}bu2-vm"
  location        = local.ecs_location
  subnet          = azurerm_subnet.ecs_subnets["${local.ecs_prefix}bu2"].id
  private_ip      = local.ecs_bu2_vm_addr
  storage_account = azurerm_storage_account.region1
  admin_username  = local.username
  admin_password  = local.password
  custom_data     = base64encode(local.vm_startup)
}

# vpngw
#----------------------------

resource "azurerm_virtual_network_gateway" "ecs_vpngw" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.ecs_prefix}vpngw"
  location            = local.ecs_location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
  enable_bgp          = false
  active_active       = true
  ip_configuration {
    name                          = "${local.ecs_prefix}link-0"
    subnet_id                     = azurerm_subnet.ecs_subnets["GatewaySubnet"].id
    public_ip_address_id          = azurerm_public_ip.ecs_vpngw_pip0.id
    private_ip_address_allocation = "Dynamic"
  }
  ip_configuration {
    name                          = "${local.ecs_prefix}link-1"
    subnet_id                     = azurerm_subnet.ecs_subnets["GatewaySubnet"].id
    public_ip_address_id          = azurerm_public_ip.ecs_vpngw_pip1.id
    private_ip_address_allocation = "Dynamic"
  }
}

# local gw
#----------------------------

# bu1

resource "azurerm_local_network_gateway" "ecs_bu1_local_gw0" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.ecs_prefix}bu1-local-gw0"
  location            = local.ecs_location
  gateway_address     = azurerm_public_ip.bu1_vpngw_pip0.ip_address
  address_space = [
    local.bu1_subnets["${local.bu1_prefix}main"].address_prefixes[0],
    local.branch1_address_space[0],
  ]
}

resource "azurerm_local_network_gateway" "ecs_bu1_local_gw1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.ecs_prefix}bu1-local-gw1"
  location            = local.ecs_location
  gateway_address     = azurerm_public_ip.bu1_vpngw_pip1.ip_address
  address_space = [
    local.bu1_subnets["${local.bu1_prefix}main"].address_prefixes[0],
    local.branch1_address_space[0],
  ]
}

# bu2

resource "azurerm_local_network_gateway" "ecs_bu2_local_gw0" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.ecs_prefix}bu2-local-gw0"
  location            = local.ecs_location
  gateway_address     = azurerm_public_ip.bu2_vpngw_pip0.ip_address
  address_space = [
    local.bu2_subnets["${local.bu2_prefix}main"].address_prefixes[0],
  ]
}

resource "azurerm_local_network_gateway" "ecs_bu2_local_gw1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.ecs_prefix}bu2-local-gw1"
  location            = local.ecs_location
  gateway_address     = azurerm_public_ip.bu2_vpngw_pip1.ip_address
  address_space = [
    local.bu2_subnets["${local.bu2_prefix}main"].address_prefixes[0],
  ]
}

# connections ipsec
#----------------------------

# bu1

resource "azurerm_virtual_network_gateway_connection" "ecs_bu1_local_gw0" {
  resource_group_name                = azurerm_resource_group.rg.name
  name                               = "${local.ecs_prefix}bu1-local-gw0"
  location                           = local.ecs_location
  type                               = "IPsec"
  enable_bgp                         = false
  virtual_network_gateway_id         = azurerm_virtual_network_gateway.ecs_vpngw.id
  local_network_gateway_id           = azurerm_local_network_gateway.ecs_bu1_local_gw0.id
  shared_key                         = local.psk
  use_policy_based_traffic_selectors = true
  traffic_selector_policy {
    local_address_cidrs  = [local.ecs_subnets["${local.ecs_prefix}bu1"].address_prefixes[0], ]
    remote_address_cidrs = [local.bu1_subnets["${local.bu1_prefix}main"].address_prefixes[0], local.branch1_address_space[0], ]
  }
}

resource "azurerm_virtual_network_gateway_connection" "ecs_bu1_local_gw1" {
  resource_group_name                = azurerm_resource_group.rg.name
  name                               = "${local.ecs_prefix}bu1-local-gw1"
  location                           = local.ecs_location
  type                               = "IPsec"
  enable_bgp                         = false
  virtual_network_gateway_id         = azurerm_virtual_network_gateway.ecs_vpngw.id
  local_network_gateway_id           = azurerm_local_network_gateway.ecs_bu1_local_gw1.id
  shared_key                         = local.psk
  use_policy_based_traffic_selectors = true
  traffic_selector_policy {
    local_address_cidrs  = [local.ecs_subnets["${local.ecs_prefix}bu1"].address_prefixes[0], ]
    remote_address_cidrs = [local.bu1_subnets["${local.bu1_prefix}main"].address_prefixes[0], local.branch1_address_space[0], ]
  }
}

# bu2

resource "azurerm_virtual_network_gateway_connection" "ecs_bu2_local_gw0" {
  resource_group_name                = azurerm_resource_group.rg.name
  name                               = "${local.ecs_prefix}bu2-local-gw0"
  location                           = local.ecs_location
  type                               = "IPsec"
  enable_bgp                         = false
  virtual_network_gateway_id         = azurerm_virtual_network_gateway.ecs_vpngw.id
  local_network_gateway_id           = azurerm_local_network_gateway.ecs_bu2_local_gw0.id
  shared_key                         = local.psk
  use_policy_based_traffic_selectors = true
  traffic_selector_policy {
    local_address_cidrs  = [local.ecs_subnets["${local.ecs_prefix}bu2"].address_prefixes[0], ]
    remote_address_cidrs = [local.bu2_subnets["${local.bu2_prefix}main"].address_prefixes[0], ]
  }
}

resource "azurerm_virtual_network_gateway_connection" "ecs_bu2_local_gw1" {
  resource_group_name                = azurerm_resource_group.rg.name
  name                               = "${local.ecs_prefix}bu2-local-gw1"
  location                           = local.ecs_location
  type                               = "IPsec"
  enable_bgp                         = false
  virtual_network_gateway_id         = azurerm_virtual_network_gateway.ecs_vpngw.id
  local_network_gateway_id           = azurerm_local_network_gateway.ecs_bu2_local_gw1.id
  shared_key                         = local.psk
  use_policy_based_traffic_selectors = true
  traffic_selector_policy {
    local_address_cidrs  = [local.ecs_subnets["${local.ecs_prefix}bu2"].address_prefixes[0], ]
    remote_address_cidrs = [local.bu2_subnets["${local.bu2_prefix}main"].address_prefixes[0], ]
  }
}
