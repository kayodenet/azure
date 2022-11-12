
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
}

# vm
#----------------------------

module "hub1_vm" {
  source          = "../modules/ubuntu"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.hub1_prefix}vm"
  location        = local.hub1_location
  subnet          = azurerm_subnet.hub1_subnets["${local.hub1_prefix}main"].id
  private_ip      = local.hub1_vm_addr
  storage_account = azurerm_storage_account.region1
  admin_username  = local.username
  admin_password  = local.password
  custom_data     = base64encode(local.vm_startup)
}
