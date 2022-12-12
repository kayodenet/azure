
####################################################
# spoke1
####################################################

# base
#----------------------------

module "spoke1" {
  source           = "../modules/base"
  resource_group   = azurerm_resource_group.rg.name
  name             = local.spoke1_prefix
  location         = local.spoke1_location
  storage_account  = azurerm_storage_account.region1
  private_dns_zone = local.spoke1_dns_zone
  dns_zone_linked_vnets = [
    module.hub1.vnet.id,
    module.hub2.vnet.id,
  ]
  dns_zone_linked_rulesets = [
    azurerm_private_dns_resolver_dns_forwarding_ruleset.hub1_onprem.id,
  ]

  vnet_config = [
    {
      address_space       = local.spoke1_address_space
      subnets             = local.spoke1_subnets
      subnets_nat_gateway = ["${local.spoke1_prefix}main", ]
    }
  ]

  vm_config = [
    {
      private_ip  = local.spoke1_vm_addr
      custom_data = base64encode(local.vm_startup)
      dns_host    = local.spoke1_vm_dns_prefix
    }
  ]
}

# nsg
#----------------------------

resource "azurerm_subnet_network_security_group_association" "spoke1_nsg_main" {
  subnet_id                 = module.spoke1.subnets["${local.spoke1_prefix}main"].id
  network_security_group_id = azurerm_network_security_group.nsg_region1_main.id
}

resource "azurerm_subnet_network_security_group_association" "spoke1_nsg_appgw" {
  subnet_id                 = module.spoke1.subnets["${local.spoke1_prefix}appgw"].id
  network_security_group_id = azurerm_network_security_group.nsg_region1_appgw.id
}

####################################################
# spoke2
####################################################

# base
#----------------------------

module "spoke2" {
  source           = "../modules/base"
  resource_group   = azurerm_resource_group.rg.name
  name             = local.spoke2_prefix
  location         = local.spoke2_location
  storage_account  = azurerm_storage_account.region1
  private_dns_zone = local.spoke2_dns_zone
  dns_zone_linked_vnets = [
    module.hub1.vnet.id,
    module.hub2.vnet.id,
  ]
  dns_zone_linked_rulesets = [
    azurerm_private_dns_resolver_dns_forwarding_ruleset.hub1_onprem.id,
  ]

  vnet_config = [
    {
      address_space = local.spoke2_address_space
      subnets       = local.spoke2_subnets
    }
  ]

  vm_config = [
    {
      private_ip  = local.spoke2_vm_addr
      custom_data = base64encode(local.vm_startup)
      dns_host    = local.spoke2_vm_dns_prefix
    }
  ]
}

# nsg
#----------------------------

resource "azurerm_subnet_network_security_group_association" "spoke2_nsg_main" {
  subnet_id                 = module.spoke2.subnets["${local.spoke2_prefix}main"].id
  network_security_group_id = azurerm_network_security_group.nsg_region1_main.id
}

resource "azurerm_subnet_network_security_group_association" "spoke2_nsg_appgw" {
  subnet_id                 = module.spoke2.subnets["${local.spoke2_prefix}appgw"].id
  network_security_group_id = azurerm_network_security_group.nsg_region1_appgw.id
}

####################################################
# spoke3
####################################################

# base
#----------------------------

module "spoke3" {
  source           = "../modules/base"
  resource_group   = azurerm_resource_group.rg.name
  name             = local.spoke3_prefix
  location         = local.spoke3_location
  storage_account  = azurerm_storage_account.region1
  private_dns_zone = local.spoke3_dns_zone
  dns_zone_linked_vnets = [
    module.hub1.vnet.id,
    module.hub2.vnet.id,
  ]
  dns_zone_linked_rulesets = [
    azurerm_private_dns_resolver_dns_forwarding_ruleset.hub1_onprem.id,
  ]

  vnet_config = [
    {
      address_space = local.spoke3_address_space
      subnets       = local.spoke3_subnets
    }
  ]

  vm_config = [
    {
      private_ip  = local.spoke3_vm_addr
      custom_data = base64encode(local.vm_startup)
      dns_host    = local.spoke3_vm_dns_prefix
    }
  ]
}

# nsg
#----------------------------

resource "azurerm_subnet_network_security_group_association" "spoke3_nsg_main" {
  subnet_id                 = module.spoke3.subnets["${local.spoke3_prefix}main"].id
  network_security_group_id = azurerm_network_security_group.nsg_region1_main.id
}

resource "azurerm_subnet_network_security_group_association" "spoke3_nsg_appgw" {
  subnet_id                 = module.spoke3.subnets["${local.spoke3_prefix}appgw"].id
  network_security_group_id = azurerm_network_security_group.nsg_region1_appgw.id
}

####################################################
# spoke4
####################################################

# base
#----------------------------

module "spoke4" {
  source           = "../modules/base"
  resource_group   = azurerm_resource_group.rg.name
  name             = local.spoke4_prefix
  location         = local.spoke4_location
  storage_account  = azurerm_storage_account.region2
  private_dns_zone = local.spoke4_dns_zone
  dns_zone_linked_vnets = [
    module.hub1.vnet.id,
    module.hub2.vnet.id,
  ]
  dns_zone_linked_rulesets = [
    azurerm_private_dns_resolver_dns_forwarding_ruleset.hub2_onprem.id,
  ]

  vnet_config = [
    {
      address_space = local.spoke4_address_space
      subnets       = local.spoke4_subnets
    }
  ]

  vm_config = [
    {
      private_ip  = local.spoke4_vm_addr
      custom_data = base64encode(local.vm_startup)
      dns_host    = local.spoke4_vm_dns_prefix
    }
  ]
}

# nsg
#----------------------------

resource "azurerm_subnet_network_security_group_association" "spoke4_nsg_main" {
  subnet_id                 = module.spoke4.subnets["${local.spoke4_prefix}main"].id
  network_security_group_id = azurerm_network_security_group.nsg_region2_main.id
}

resource "azurerm_subnet_network_security_group_association" "spoke4_nsg_appgw" {
  subnet_id                 = module.spoke4.subnets["${local.spoke4_prefix}appgw"].id
  network_security_group_id = azurerm_network_security_group.nsg_region2_appgw.id
}

####################################################
# spoke5
####################################################

# base
#----------------------------

module "spoke5" {
  source           = "../modules/base"
  resource_group   = azurerm_resource_group.rg.name
  name             = local.spoke5_prefix
  location         = local.spoke5_location
  storage_account  = azurerm_storage_account.region2
  private_dns_zone = local.spoke5_dns_zone
  dns_zone_linked_vnets = [
    module.hub1.vnet.id,
    module.hub2.vnet.id,
  ]
  dns_zone_linked_rulesets = [
    azurerm_private_dns_resolver_dns_forwarding_ruleset.hub2_onprem.id,
  ]

  vnet_config = [
    {
      address_space = local.spoke5_address_space
      subnets       = local.spoke5_subnets
    }
  ]

  vm_config = [
    {
      private_ip  = local.spoke5_vm_addr
      custom_data = base64encode(local.vm_startup)
      dns_host    = local.spoke5_vm_dns_prefix
    }
  ]
}

# nsg
#----------------------------

resource "azurerm_subnet_network_security_group_association" "spoke5_nsg_main" {
  subnet_id                 = module.spoke5.subnets["${local.spoke5_prefix}main"].id
  network_security_group_id = azurerm_network_security_group.nsg_region2_main.id
}

resource "azurerm_subnet_network_security_group_association" "spoke5_nsg_appgw" {
  subnet_id                 = module.spoke5.subnets["${local.spoke5_prefix}appgw"].id
  network_security_group_id = azurerm_network_security_group.nsg_region2_appgw.id
}

####################################################
# spoke6
####################################################

# base
#----------------------------

module "spoke6" {
  source           = "../modules/base"
  resource_group   = azurerm_resource_group.rg.name
  name             = local.spoke6_prefix
  location         = local.spoke6_location
  storage_account  = azurerm_storage_account.region2
  private_dns_zone = local.spoke6_dns_zone
  dns_zone_linked_vnets = [
    module.hub1.vnet.id,
    module.hub2.vnet.id,
  ]
  dns_zone_linked_rulesets = [
    azurerm_private_dns_resolver_dns_forwarding_ruleset.hub2_onprem.id,
  ]

  vnet_config = [
    {
      address_space = local.spoke6_address_space
      subnets       = local.spoke6_subnets
    }
  ]

  vm_config = [
    {
      private_ip  = local.spoke6_vm_addr
      custom_data = base64encode(local.vm_startup)
      dns_host    = local.spoke6_vm_dns_prefix
    }
  ]
}

# nsg
#----------------------------

resource "azurerm_subnet_network_security_group_association" "spoke6_nsg_main" {
  subnet_id                 = module.spoke6.subnets["${local.spoke6_prefix}main"].id
  network_security_group_id = azurerm_network_security_group.nsg_region2_main.id
}

resource "azurerm_subnet_network_security_group_association" "spoke6_nsg_appgw" {
  subnet_id                 = module.spoke6.subnets["${local.spoke6_prefix}appgw"].id
  network_security_group_id = azurerm_network_security_group.nsg_region2_appgw.id
}
