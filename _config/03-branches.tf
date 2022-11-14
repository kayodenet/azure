
# branch1
#----------------------------

# vnet

resource "azurerm_virtual_network" "branch1_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch1_prefix}vnet"
  address_space       = local.branch1_address_space
  location            = local.branch1_location
}

# subnets

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

module "branch1_vm" {
  source          = "../modules/ubuntu"
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

# branch2
#----------------------------

# vnet

resource "azurerm_virtual_network" "branch2_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch2_prefix}vnet"
  address_space       = local.branch2_address_space
  location            = local.branch2_location
}

# subnets

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

module "branch2_vm" {
  source          = "../modules/ubuntu"
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

# branch3
#----------------------------

# vnet

resource "azurerm_virtual_network" "branch3_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch3_prefix}vnet"
  address_space       = local.branch3_address_space
  location            = local.branch3_location
}

# subnets

resource "azurerm_subnet" "branch3_subnets" {
  for_each             = local.branch3_subnets
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.branch3_vnet.name
  name                 = each.key
  address_prefixes     = each.value.address_prefixes
}

resource "azurerm_subnet_network_security_group_association" "branch3_subnets" {
  subnet_id                 = azurerm_subnet.branch3_subnets["${local.branch3_prefix}main"].id
  network_security_group_id = azurerm_network_security_group.nsg_region2_main.id
}

# vm

module "branch3_vm" {
  source          = "../modules/ubuntu"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.branch3_prefix}vm"
  location        = local.branch3_location
  subnet          = azurerm_subnet.branch3_subnets["${local.branch3_prefix}main"].id
  private_ip      = local.branch3_vm_addr
  storage_account = azurerm_storage_account.region2
  admin_username  = local.username
  admin_password  = local.password
  custom_data     = base64encode(local.vm_startup)
}

# branch4
#----------------------------

# vnet

resource "azurerm_virtual_network" "branch4_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch4_prefix}vnet"
  address_space       = local.branch4_address_space
  location            = local.branch4_location
}

# subnets

resource "azurerm_subnet" "branch4_subnets" {
  for_each             = local.branch4_subnets
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.branch4_vnet.name
  name                 = each.key
  address_prefixes     = each.value.address_prefixes
}

resource "azurerm_subnet_network_security_group_association" "branch4_subnets" {
  subnet_id                 = azurerm_subnet.branch4_subnets["${local.branch4_prefix}main"].id
  network_security_group_id = azurerm_network_security_group.nsg_region2_main.id
}

# vm

module "branch4_vm" {
  source          = "../modules/ubuntu"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.branch4_prefix}vm"
  location        = local.branch4_location
  subnet          = azurerm_subnet.branch4_subnets["${local.branch4_prefix}main"].id
  private_ip      = local.branch4_vm_addr
  storage_account = azurerm_storage_account.region2
  admin_username  = local.username
  admin_password  = local.password
  custom_data     = base64encode(local.vm_startup)
}

