
# spoke1
#----------------------------

# vnet

resource "azurerm_virtual_network" "spoke1_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.spoke1_prefix}vnet"
  address_space       = local.spoke1_address_space
  location            = local.spoke1_location
}

# subnets

resource "azurerm_subnet" "spoke1_subnets" {
  for_each             = local.spoke1_subnets
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke1_vnet.name
  name                 = each.key
  address_prefixes     = each.value.address_prefixes
}

resource "azurerm_subnet_network_security_group_association" "spoke1_subnets_main" {
  subnet_id                 = azurerm_subnet.spoke1_subnets["${local.spoke1_prefix}main"].id
  network_security_group_id = azurerm_network_security_group.nsg_region1_main.id
}

resource "azurerm_subnet_network_security_group_association" "spoke1_subnets_appgw" {
  subnet_id                 = azurerm_subnet.spoke1_subnets["${local.spoke1_prefix}appgw"].id
  network_security_group_id = azurerm_network_security_group.nsg_region1_appgw.id
}

# vm

module "spoke1_vm" {
  source          = "../../modules/ubuntu"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.spoke1_prefix}vm"
  location        = local.spoke1_location
  subnet          = azurerm_subnet.spoke1_subnets["${local.spoke1_prefix}main"].id
  private_ip      = local.spoke1_vm_addr
  storage_account = azurerm_storage_account.region1
  admin_username  = local.username
  admin_password  = local.password
  custom_data     = base64encode(local.vm_startup)
}

# spoke2
#----------------------------

# vnet

resource "azurerm_virtual_network" "spoke2_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.spoke2_prefix}vnet"
  address_space       = local.spoke2_address_space
  location            = local.spoke2_location
}

# subnets

resource "azurerm_subnet" "spoke2_subnets" {
  for_each             = local.spoke2_subnets
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke2_vnet.name
  name                 = each.key
  address_prefixes     = each.value.address_prefixes
}

resource "azurerm_subnet_network_security_group_association" "spoke2_subnets_main" {
  subnet_id                 = azurerm_subnet.spoke2_subnets["${local.spoke2_prefix}main"].id
  network_security_group_id = azurerm_network_security_group.nsg_region1_main.id
}

resource "azurerm_subnet_network_security_group_association" "spoke2_subnets_appgw" {
  subnet_id                 = azurerm_subnet.spoke2_subnets["${local.spoke2_prefix}appgw"].id
  network_security_group_id = azurerm_network_security_group.nsg_region1_appgw.id
}

# vm

module "spoke2_vm" {
  source          = "../../modules/ubuntu"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.spoke2_prefix}vm"
  location        = local.spoke2_location
  subnet          = azurerm_subnet.spoke2_subnets["${local.spoke2_prefix}main"].id
  private_ip      = local.spoke2_vm_addr
  storage_account = azurerm_storage_account.region1
  admin_username  = local.username
  admin_password  = local.password
  custom_data     = base64encode(local.vm_startup)
}

# spoke3
#----------------------------

# vnet

resource "azurerm_virtual_network" "spoke3_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.spoke3_prefix}vnet"
  address_space       = local.spoke3_address_space
  location            = local.spoke3_location
}

# subnets

resource "azurerm_subnet" "spoke3_subnets" {
  for_each             = local.spoke3_subnets
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke3_vnet.name
  name                 = each.key
  address_prefixes     = each.value.address_prefixes
}

resource "azurerm_subnet_network_security_group_association" "spoke3_subnets_main" {
  subnet_id                 = azurerm_subnet.spoke3_subnets["${local.spoke3_prefix}main"].id
  network_security_group_id = azurerm_network_security_group.nsg_region1_main.id
}

resource "azurerm_subnet_network_security_group_association" "spoke3_subnets_appgw" {
  subnet_id                 = azurerm_subnet.spoke3_subnets["${local.spoke3_prefix}appgw"].id
  network_security_group_id = azurerm_network_security_group.nsg_region1_appgw.id
}

# vm

module "spoke3_vm" {
  source          = "../../modules/ubuntu"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.spoke3_prefix}vm"
  location        = local.spoke3_location
  subnet          = azurerm_subnet.spoke3_subnets["${local.spoke3_prefix}main"].id
  private_ip      = local.spoke3_vm_addr
  storage_account = azurerm_storage_account.region1
  admin_username  = local.username
  admin_password  = local.password
  custom_data     = base64encode(local.vm_startup)
}

# spoke4
#----------------------------

# vnet

resource "azurerm_virtual_network" "spoke4_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.spoke4_prefix}vnet"
  address_space       = local.spoke4_address_space
  location            = local.spoke4_location
}

# subnets

resource "azurerm_subnet" "spoke4_subnets" {
  for_each             = local.spoke4_subnets
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke4_vnet.name
  name                 = each.key
  address_prefixes     = each.value.address_prefixes
}

resource "azurerm_subnet_network_security_group_association" "spoke4_subnets_main" {
  subnet_id                 = azurerm_subnet.spoke4_subnets["${local.spoke4_prefix}main"].id
  network_security_group_id = azurerm_network_security_group.nsg_region2_main.id
}

resource "azurerm_subnet_network_security_group_association" "spoke4_subnets_appgw" {
  subnet_id                 = azurerm_subnet.spoke4_subnets["${local.spoke4_prefix}appgw"].id
  network_security_group_id = azurerm_network_security_group.nsg_region2_appgw.id
}

# vm

module "spoke4_vm" {
  source          = "../../modules/ubuntu"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.spoke4_prefix}vm"
  location        = local.spoke4_location
  subnet          = azurerm_subnet.spoke4_subnets["${local.spoke4_prefix}main"].id
  private_ip      = local.spoke4_vm_addr
  storage_account = azurerm_storage_account.region2
  admin_username  = local.username
  admin_password  = local.password
  custom_data     = base64encode(local.vm_startup)
}

# spoke5
#----------------------------

# vnet

resource "azurerm_virtual_network" "spoke5_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.spoke5_prefix}vnet"
  address_space       = local.spoke5_address_space
  location            = local.spoke5_location
}

# subnets

resource "azurerm_subnet" "spoke5_subnets" {
  for_each             = local.spoke5_subnets
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke5_vnet.name
  name                 = each.key
  address_prefixes     = each.value.address_prefixes
}

resource "azurerm_subnet_network_security_group_association" "spoke5_subnets_main" {
  subnet_id                 = azurerm_subnet.spoke5_subnets["${local.spoke5_prefix}main"].id
  network_security_group_id = azurerm_network_security_group.nsg_region2_main.id
}

resource "azurerm_subnet_network_security_group_association" "spoke5_subnets_appgw" {
  subnet_id                 = azurerm_subnet.spoke5_subnets["${local.spoke5_prefix}appgw"].id
  network_security_group_id = azurerm_network_security_group.nsg_region2_appgw.id
}

# vm

module "spoke5_vm" {
  source          = "../../modules/ubuntu"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.spoke5_prefix}vm"
  location        = local.spoke5_location
  subnet          = azurerm_subnet.spoke5_subnets["${local.spoke5_prefix}main"].id
  private_ip      = local.spoke5_vm_addr
  storage_account = azurerm_storage_account.region2
  admin_username  = local.username
  admin_password  = local.password
  custom_data     = base64encode(local.vm_startup)
}

# spoke6
#----------------------------

# vnet

resource "azurerm_virtual_network" "spoke6_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.spoke6_prefix}vnet"
  address_space       = local.spoke6_address_space
  location            = local.spoke6_location
}

# subnets

resource "azurerm_subnet" "spoke6_subnets" {
  for_each             = local.spoke6_subnets
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke6_vnet.name
  name                 = each.key
  address_prefixes     = each.value.address_prefixes
}

resource "azurerm_subnet_network_security_group_association" "spoke6_subnets_main" {
  subnet_id                 = azurerm_subnet.spoke6_subnets["${local.spoke6_prefix}main"].id
  network_security_group_id = azurerm_network_security_group.nsg_region2_main.id
}

resource "azurerm_subnet_network_security_group_association" "spoke6_subnets_appgw" {
  subnet_id                 = azurerm_subnet.spoke6_subnets["${local.spoke6_prefix}appgw"].id
  network_security_group_id = azurerm_network_security_group.nsg_region2_appgw.id
}

# vm

module "spoke6_vm" {
  source          = "../../modules/ubuntu"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.spoke6_prefix}vm"
  location        = local.spoke6_location
  subnet          = azurerm_subnet.spoke6_subnets["${local.spoke6_prefix}main"].id
  private_ip      = local.spoke6_vm_addr
  storage_account = azurerm_storage_account.region2
  admin_username  = local.username
  admin_password  = local.password
  custom_data     = base64encode(local.vm_startup)
}
