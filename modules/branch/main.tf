
# vnet
#----------------------------

resource "azurerm_virtual_network" "vnet" {
  resource_group_name = var.resource_group_name
  name                = "${var.prefix}vnet"
  address_space       = var.address_space
  location            = var.location
}

# subnets
#----------------------------

resource "azurerm_subnet" "subnets" {
  for_each             = var.subnets
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  name                 = each.key
  address_prefixes     = each.value.address_prefixes
}

resource "azurerm_subnet_network_security_group_association" "subnets" {
  subnet_id                 = azurerm_subnet.subnets["${local.prefix}main"].id
  network_security_group_id = var.network_security_group_id
}

# vm
#----------------------------

module "vm" {
  source              = "../modules/ubuntu"
  resource_group_name = var.resource_group_name
  name                = var.prefix
  location            = var.location
  subnet              = azurerm_subnet.subnets["${var.prefix}main"].id
  private_ip          = var.private_ip
  storage_account     = var.storage_account
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  custom_data         = var.custom_data
}
