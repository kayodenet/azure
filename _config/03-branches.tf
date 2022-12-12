
####################################################
# branch1
####################################################

# base
#----------------------------

module "branch1" {
  source          = "../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  name            = local.branch1_prefix
  location        = local.branch1_location
  storage_account = azurerm_storage_account.region1

  vnet_config = [
    {
      address_space = local.branch1_address_space
      subnets       = local.branch1_subnets
      dns_servers   = [local.branch1_dns_addr, ]
    }
  ]

  vm_config = [
    {
      private_ip  = local.branch1_vm_addr
      custom_data = base64encode(local.vm_startup)
    }
  ]

  dns_config = [
    {
      private_ip       = local.branch1_dns_addr
      custom_data      = base64encode(local.branch_unbound_config)
      use_vm_extension = true
    }
  ]
}

# nsg
#----------------------------

resource "azurerm_subnet_network_security_group_association" "branch1_nsg_main" {
  subnet_id                 = module.branch1.subnets["${local.branch1_prefix}main"].id
  network_security_group_id = azurerm_network_security_group.nsg_region1_main.id
}

resource "azurerm_subnet_network_security_group_association" "branch1_nsg_int" {
  subnet_id                 = module.branch1.subnets["${local.branch1_prefix}int"].id
  network_security_group_id = azurerm_network_security_group.nsg_region1_main.id
}

resource "azurerm_subnet_network_security_group_association" "branch1_nsg_ext" {
  subnet_id                 = module.branch1.subnets["${local.branch1_prefix}ext"].id
  network_security_group_id = azurerm_network_security_group.nsg_region1_nva.id
}

# files
#----------------------------

resource "local_file" "branch1_dns" {
  content  = local.branch_unbound_config
  filename = "_output/branch1-dns.sh"
}

####################################################
# branch2
####################################################

# base
#----------------------------

module "branch2" {
  source          = "../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  name            = local.branch2_prefix
  location        = local.branch2_location
  storage_account = azurerm_storage_account.region1

  vnet_config = [
    {
      address_space = local.branch2_address_space
      subnets       = local.branch2_subnets
      dns_servers   = [local.branch2_dns_addr, ]
    }
  ]

  vm_config = [
    {
      private_ip  = local.branch2_vm_addr
      custom_data = base64encode(local.vm_startup)
    }
  ]

  dns_config = [
    {
      private_ip       = local.branch2_dns_addr
      custom_data      = base64encode(local.branch_unbound_config)
      use_vm_extension = true
    }
  ]
}

# nsg
#----------------------------

resource "azurerm_subnet_network_security_group_association" "branch2_nsg_main" {
  subnet_id                 = module.branch2.subnets["${local.branch2_prefix}main"].id
  network_security_group_id = azurerm_network_security_group.nsg_region1_main.id
}

resource "azurerm_subnet_network_security_group_association" "branch2_nsg_int" {
  subnet_id                 = module.branch2.subnets["${local.branch2_prefix}int"].id
  network_security_group_id = azurerm_network_security_group.nsg_region1_main.id
}

resource "azurerm_subnet_network_security_group_association" "branch2_nsg_ext" {
  subnet_id                 = module.branch2.subnets["${local.branch2_prefix}ext"].id
  network_security_group_id = azurerm_network_security_group.nsg_region1_nva.id
}

# files
#----------------------------

resource "local_file" "branch2_dns" {
  content  = local.branch_unbound_config
  filename = "_output/branch2-dns.sh"
}

# ergw
#----------------------------

resource "azurerm_virtual_network_gateway" "branch2_ergw" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch2_prefix}ergw"
  location            = local.branch2_location
  type                = "ExpressRoute"
  vpn_type            = "RouteBased"
  sku                 = "Standard"
  enable_bgp          = true
  active_active       = false
  ip_configuration {
    name                          = "${local.branch2_prefix}link-0"
    subnet_id                     = module.branch2.subnets["GatewaySubnet"].id
    public_ip_address_id          = azurerm_public_ip.branch2_ergw_pip.id
    private_ip_address_allocation = "Dynamic"
  }
}

####################################################
# branch3
####################################################

# base
#----------------------------

module "branch3" {
  source          = "../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  name            = local.branch3_prefix
  location        = local.branch3_location
  storage_account = azurerm_storage_account.region2

  vnet_config = [
    {
      address_space = local.branch3_address_space
      subnets       = local.branch3_subnets
      dns_servers   = [local.branch3_dns_addr, ]
    }
  ]

  vm_config = [
    {
      private_ip  = local.branch3_vm_addr
      custom_data = base64encode(local.vm_startup)
    }
  ]

  dns_config = [
    {
      private_ip       = local.branch3_dns_addr
      custom_data      = base64encode(local.branch_unbound_config)
      use_vm_extension = true
    }
  ]
}

# nsg
#----------------------------

resource "azurerm_subnet_network_security_group_association" "branch3_nsg_main" {
  subnet_id                 = module.branch3.subnets["${local.branch3_prefix}main"].id
  network_security_group_id = azurerm_network_security_group.nsg_region2_main.id
}

resource "azurerm_subnet_network_security_group_association" "branch3_nsg_int" {
  subnet_id                 = module.branch3.subnets["${local.branch3_prefix}int"].id
  network_security_group_id = azurerm_network_security_group.nsg_region2_main.id
}

resource "azurerm_subnet_network_security_group_association" "branch3_nsg_ext" {
  subnet_id                 = module.branch3.subnets["${local.branch3_prefix}ext"].id
  network_security_group_id = azurerm_network_security_group.nsg_region2_nva.id
}

# files
#----------------------------

resource "local_file" "branch3_dns" {
  content  = local.branch_unbound_config
  filename = "_output/branch3-dns.sh"
}




