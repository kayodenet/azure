
# vnet
#----------------------------

resource "azurerm_virtual_network" "branch1_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch1_prefix}vnet"
  address_space       = local.branch1_address_space
  location            = local.branch1_location
}

# subnets
#----------------------------

resource "azurerm_subnet" "branch1_subnets" {
  for_each             = local.branch1_subnets
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.branch1_vnet.name
  name                 = each.key
  address_prefixes     = each.value.address_prefixes
}

resource "azurerm_subnet_network_security_group_association" "branch1_subnets" {
  subnet_id                 = azurerm_subnet.branch1_subnets["${local.branch1_prefix}main"].id
  network_security_group_id = azurerm_network_security_group.nsg_region1_main.id
}

# vm
#----------------------------

module "branch1_vm" {
  source          = "../../../modules/ubuntu"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.branch1_prefix}vm"
  location        = local.branch1_location
  subnet          = azurerm_subnet.branch1_subnets["${local.branch1_prefix}main"].id
  private_ip      = local.branch1_vm_addr
  storage_account = azurerm_storage_account.region1
  admin_username  = local.username
  admin_password  = local.password
  custom_data     = base64encode(local.vm_startup)
}

####################################################
# er
####################################################

# ergw
#----------------------------

resource "azurerm_virtual_network_gateway" "branch1_ergw" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch1_prefix}ergw"
  location            = local.branch1_location
  type                = "ExpressRoute"
  vpn_type            = "RouteBased"
  sku                 = "Standard"
  enable_bgp          = true
  active_active       = false
  ip_configuration {
    name                          = "${local.branch1_prefix}link-0"
    subnet_id                     = azurerm_subnet.branch1_subnets["GatewaySubnet"].id
    public_ip_address_id          = azurerm_public_ip.branch1_ergw_pip0.id
    private_ip_address_allocation = "Dynamic"
  }
}
