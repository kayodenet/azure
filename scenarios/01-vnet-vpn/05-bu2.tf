
# vnet
#----------------------------

resource "azurerm_virtual_network" "bu2_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.bu2_prefix}vnet"
  address_space       = local.bu2_address_space
  location            = local.bu2_location
}

# subnets
#----------------------------

resource "azurerm_subnet" "bu2_subnets" {
  for_each             = local.bu2_subnets
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.bu2_vnet.name
  name                 = each.key
  address_prefixes     = each.value.address_prefixes
}

/*resource "azurerm_subnet_network_security_group_association" "bu2_subnets_main" {
  subnet_id                 = azurerm_subnet.bu2_subnets["${local.bu2_prefix}main"].id
  network_security_group_id = azurerm_network_security_group.nsg_region1_main.id
}*/

# vm
#----------------------------

module "bu2_vm" {
  source          = "../../modules/ubuntu"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.bu2_prefix}vm"
  location        = local.bu2_location
  subnet          = azurerm_subnet.bu2_subnets["${local.bu2_prefix}main"].id
  private_ip      = local.bu2_vm_addr
  storage_account = azurerm_storage_account.region1
  admin_username  = local.username
  admin_password  = local.password
  custom_data     = base64encode(local.vm_startup)
}

####################################################
# vpn
####################################################

# vpngw
#----------------------------

resource "azurerm_virtual_network_gateway" "bu2_vpngw" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.bu2_prefix}vpngw"
  location            = local.bu2_location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
  enable_bgp          = false
  active_active       = true
  ip_configuration {
    name                          = "${local.bu2_prefix}link-0"
    subnet_id                     = azurerm_subnet.bu2_subnets["GatewaySubnet"].id
    public_ip_address_id          = azurerm_public_ip.bu2_vpngw_pip0.id
    private_ip_address_allocation = "Dynamic"
  }
  ip_configuration {
    name                          = "${local.bu2_prefix}link-1"
    subnet_id                     = azurerm_subnet.bu2_subnets["GatewaySubnet"].id
    public_ip_address_id          = azurerm_public_ip.bu2_vpngw_pip1.id
    private_ip_address_allocation = "Dynamic"
  }
}

# local gw
#----------------------------

resource "azurerm_local_network_gateway" "bu2_ecs_local_gw0" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.bu2_prefix}ecs-local-gw0"
  location            = local.bu2_location
  gateway_address     = azurerm_public_ip.ecs_vpngw_pip0.ip_address
  address_space = [
    local.ecs_subnets["${local.ecs_prefix}bu2"].address_prefixes[0],
  ]
}

resource "azurerm_local_network_gateway" "bu2_ecs_local_gw1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.bu2_prefix}ecs-local-gw1"
  location            = local.bu2_location
  gateway_address     = azurerm_public_ip.ecs_vpngw_pip1.ip_address
  address_space = [
    local.ecs_subnets["${local.ecs_prefix}bu2"].address_prefixes[0],
  ]
}

# connections
#----------------------------

# bu2

resource "azurerm_virtual_network_gateway_connection" "bu2_ecs_local_gw0" {
  resource_group_name                = azurerm_resource_group.rg.name
  name                               = "${local.bu2_prefix}ecs-local-gw0"
  location                           = local.bu2_location
  type                               = "IPsec"
  enable_bgp                         = false
  virtual_network_gateway_id         = azurerm_virtual_network_gateway.bu2_vpngw.id
  local_network_gateway_id           = azurerm_local_network_gateway.bu2_ecs_local_gw0.id
  shared_key                         = local.psk
  use_policy_based_traffic_selectors = true
  traffic_selector_policy {
    local_address_cidrs  = [local.bu2_subnets["${local.bu2_prefix}main"].address_prefixes[0], ]
    remote_address_cidrs = [local.ecs_subnets["${local.ecs_prefix}bu2"].address_prefixes[0], ]
  }
}

resource "azurerm_virtual_network_gateway_connection" "bu2_ecs_local_gw1" {
  resource_group_name                = azurerm_resource_group.rg.name
  name                               = "${local.bu2_prefix}bu2-local-gw1"
  location                           = local.bu2_location
  type                               = "IPsec"
  enable_bgp                         = false
  virtual_network_gateway_id         = azurerm_virtual_network_gateway.bu2_vpngw.id
  local_network_gateway_id           = azurerm_local_network_gateway.bu2_ecs_local_gw1.id
  shared_key                         = local.psk
  use_policy_based_traffic_selectors = true
  traffic_selector_policy {
    local_address_cidrs  = [local.bu2_subnets["${local.bu2_prefix}main"].address_prefixes[0], ]
    remote_address_cidrs = [local.ecs_subnets["${local.ecs_prefix}bu2"].address_prefixes[0], ]
  }
}
