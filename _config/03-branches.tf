
# branch1
#----------------------------

# vnet

resource "azurerm_virtual_network" "branch1_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch1_prefix}vnet"
  address_space       = local.branch1_address_space
  location            = local.branch1_location
  dns_servers         = ["168.63.129.16", local.branch1_dns_addr, ]
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

# dns

resource "local_file" "branch1_dns" {
  content  = local.branch_unbound_config
  filename = "_output/branch1-dns.sh"
}

module "branch1_dns_cloud_init" {
  source          = "../modules/cloud-config-gen"
  container_image = null
  files = { "/var/tmp/unbound.sh" = {
    owner       = "root"
    permissions = "0744"
    content = templatefile("../scripts/unbound.sh", local.branch_unbound_vars) }
  }
  run_commands = [
    #". /var/tmp/unbound.sh",
  ]
}

module "branch1_dns" {
  source           = "../modules/debian"
  resource_group   = azurerm_resource_group.rg.name
  name             = "${local.branch1_prefix}dns"
  location         = local.branch1_location
  subnet           = azurerm_subnet.branch1_subnets["${local.branch1_prefix}main"].id
  private_ip       = local.branch1_dns_addr
  storage_account  = azurerm_storage_account.region1
  admin_username   = local.username
  admin_password   = local.password
  custom_data      = base64encode(local.branch_unbound_config)
  use_vm_extension = true
  #custom_data     = base64encode(module.branch1_dns_cloud_init.cloud_config)
}

# vm

module "branch1_vm" {
  source          = "../modules/ubuntu"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.branch1_prefix}vm"
  location        = local.branch1_location
  dns_servers     = [local.branch1_dns_addr, ]
  subnet          = azurerm_subnet.branch1_subnets["${local.branch1_prefix}main"].id
  private_ip      = local.branch1_vm_addr
  storage_account = azurerm_storage_account.region1
  admin_username  = local.username
  admin_password  = local.password
  custom_data     = base64encode(local.vm_startup)
  depends_on      = [module.branch1_dns]
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

# dns

resource "local_file" "branch2_dns" {
  content  = local.branch_unbound_config
  filename = "_output/branch2-dns.sh"
}

module "branch2_dns_cloud_init" {
  source          = "../modules/cloud-config-gen"
  container_image = null
  files = { "/var/tmp/unbound.sh" = {
    owner       = "root"
    permissions = "0744"
    content = templatefile("../scripts/unbound.sh", local.branch_unbound_vars) }
  }
  run_commands = [
    #". /var/tmp/unbound.sh",
  ]
}

module "branch2_dns" {
  source           = "../modules/debian"
  resource_group   = azurerm_resource_group.rg.name
  name             = "${local.branch2_prefix}dns"
  location         = local.branch2_location
  subnet           = azurerm_subnet.branch2_subnets["${local.branch2_prefix}main"].id
  private_ip       = local.branch2_dns_addr
  storage_account  = azurerm_storage_account.region1
  admin_username   = local.username
  admin_password   = local.password
  custom_data      = base64encode(local.branch_unbound_config)
  use_vm_extension = true
  #custom_data     = base64encode(module.branch2_dns_cloud_init.cloud_config)
}

# vm

module "branch2_vm" {
  source          = "../modules/ubuntu"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.branch2_prefix}vm"
  location        = local.branch2_location
  dns_servers     = [local.branch2_dns_addr, ]
  subnet          = azurerm_subnet.branch2_subnets["${local.branch2_prefix}main"].id
  private_ip      = local.branch2_vm_addr
  storage_account = azurerm_storage_account.region1
  admin_username  = local.username
  admin_password  = local.password
  custom_data     = base64encode(local.vm_startup)
  depends_on      = [module.branch2_dns]
}

# ergw

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
    subnet_id                     = azurerm_subnet.branch2_subnets["GatewaySubnet"].id
    public_ip_address_id          = azurerm_public_ip.branch2_ergw_pip.id
    private_ip_address_allocation = "Dynamic"
  }
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

# dns

resource "local_file" "branch3_dns" {
  content  = local.branch_unbound_config
  filename = "_output/branch3-dns.sh"
}

module "branch3_dns_cloud_init" {
  source          = "../modules/cloud-config-gen"
  container_image = null
  files = { "/var/tmp/unbound.sh" = {
    owner       = "root"
    permissions = "0744"
    content = templatefile("../scripts/unbound.sh", local.branch_unbound_vars) }
  }
  run_commands = [
    #". /var/tmp/unbound.sh",
  ]
}

module "branch3_dns" {
  source           = "../modules/debian"
  resource_group   = azurerm_resource_group.rg.name
  name             = "${local.branch3_prefix}dns"
  location         = local.branch3_location
  subnet           = azurerm_subnet.branch3_subnets["${local.branch3_prefix}main"].id
  private_ip       = local.branch3_dns_addr
  storage_account  = azurerm_storage_account.region2
  admin_username   = local.username
  admin_password   = local.password
  custom_data      = base64encode(local.branch_unbound_config)
  use_vm_extension = true
  #custom_data     = base64encode(module.branch3_dns_cloud_init.cloud_config)
}

# vm

module "branch3_vm" {
  source          = "../modules/ubuntu"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.branch3_prefix}vm"
  location        = local.branch3_location
  dns_servers     = [local.branch3_dns_addr, ]
  subnet          = azurerm_subnet.branch3_subnets["${local.branch3_prefix}main"].id
  private_ip      = local.branch3_vm_addr
  storage_account = azurerm_storage_account.region2
  admin_username  = local.username
  admin_password  = local.password
  custom_data     = base64encode(local.vm_startup)
  depends_on      = [module.branch3_dns]
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

# dns

resource "local_file" "branch4_dns" {
  content  = local.branch_unbound_config
  filename = "_output/branch4-dns.sh"
}

module "branch4_dns_cloud_init" {
  source          = "../modules/cloud-config-gen"
  container_image = null
  files = { "/var/tmp/unbound.sh" = {
    owner       = "root"
    permissions = "0744"
    content = templatefile("../scripts/unbound.sh", local.branch_unbound_vars) }
  }
  run_commands = [
    #". /var/tmp/unbound.sh",
  ]
}

module "branch4_dns" {
  source           = "../modules/debian"
  resource_group   = azurerm_resource_group.rg.name
  name             = "${local.branch4_prefix}dns"
  location         = local.branch4_location
  subnet           = azurerm_subnet.branch4_subnets["${local.branch4_prefix}main"].id
  private_ip       = local.branch4_dns_addr
  storage_account  = azurerm_storage_account.region2
  admin_username   = local.username
  admin_password   = local.password
  custom_data      = base64encode(local.branch_unbound_config)
  use_vm_extension = true
  #custom_data     = base64encode(module.branch4_dns_cloud_init.cloud_config)
}

# vm

module "branch4_vm" {
  source          = "../modules/ubuntu"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.branch4_prefix}vm"
  location        = local.branch4_location
  dns_servers     = [local.branch4_dns_addr, ]
  subnet          = azurerm_subnet.branch4_subnets["${local.branch4_prefix}main"].id
  private_ip      = local.branch4_vm_addr
  storage_account = azurerm_storage_account.region2
  admin_username  = local.username
  admin_password  = local.password
  custom_data     = base64encode(local.vm_startup)
  depends_on      = [module.branch4_dns]
}

