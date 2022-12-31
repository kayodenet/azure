
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

  nsg_subnets = {
    "main" = azurerm_network_security_group.nsg_region1_main.id
    "int"  = azurerm_network_security_group.nsg_region1_main.id
    "ext"  = azurerm_network_security_group.nsg_region1_nva.id
  }

  vnet_config = [
    {
      address_space = local.branch1_address_space
      subnets       = local.branch1_subnets
      dns_servers   = [local.branch1_dns_addr, ]
      enable_vpngw  = false
      enable_ergw   = false
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

  nsg_subnets = {
    "main" = azurerm_network_security_group.nsg_region1_main.id
    "int"  = azurerm_network_security_group.nsg_region1_main.id
    "ext"  = azurerm_network_security_group.nsg_region1_nva.id
  }


  vnet_config = [
    {
      address_space = local.branch2_address_space
      subnets       = local.branch2_subnets
      dns_servers   = [local.branch2_dns_addr, ]
      enable_vpngw  = false
      #enable_ergw   = true
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

# files
#----------------------------

resource "local_file" "branch2_dns" {
  content  = local.branch_unbound_config
  filename = "_output/branch2-dns.sh"
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

  nsg_subnets = {
    "main" = azurerm_network_security_group.nsg_region2_main.id
    "int"  = azurerm_network_security_group.nsg_region2_main.id
    "ext"  = azurerm_network_security_group.nsg_region2_nva.id
  }


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

# files
#----------------------------

resource "local_file" "branch3_dns" {
  content  = local.branch_unbound_config
  filename = "_output/branch3-dns.sh"
}




