
# vm startup scripts
#----------------------------

locals {
  prefix       = "A"
  hub1_nva_asn = "65000"
  hub2_nva_asn = "65000"
  mypip        = chomp(data.http.mypip.response_body)
  vm_startup = templatefile("../scripts/vm.sh", {
    TARGETS_IP = [
      local.branch1_vm_addr,
      local.branch2_vm_addr,
      local.branch3_vm_addr,
      local.branch4_vm_addr,
      local.hub1_vm_addr,
      local.hub2_vm_addr,
      local.spoke1_vm_addr,
      local.spoke2_vm_addr,
      local.spoke3_vm_addr,
      local.spoke4_vm_addr,
      local.spoke5_vm_addr,
      local.spoke6_vm_addr,
    ]
    TARGETS_DNS = [
      local.branch1_vm_dns,
      local.branch2_vm_dns,
      local.branch3_vm_dns,
      local.branch4_vm_dns,
      local.spoke1_vm_dns,
      local.spoke2_vm_dns,
      local.spoke3_vm_dns,
      local.spoke4_vm_dns,
      local.spoke5_vm_dns,
      local.spoke6_vm_dns,
    ]
  })
}

####################################################
# standard hubs (transit vnets)
####################################################

# hub1
#----------------------------

resource "azurerm_public_ip" "hub1_vpngw_pip0" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}vpngw-pip0"
  location            = local.region1
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "hub1_vpngw_pip1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}vpngw-pip1"
  location            = local.region1
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "hub1_ars_pip" {
  name                = "${local.hub1_prefix}ars-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.region1
  sku                 = "Standard"
  allocation_method   = "Static"
}

# hub2
#----------------------------

resource "azurerm_public_ip" "hub2_vpngw_pip0" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}vpngw-pip0"
  location            = local.region2
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "hub2_vpngw_pip1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}vpngw-pip1"
  location            = local.region2
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "hub2_ars_pip" {
  name                = "${local.hub2_prefix}ars-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.region2
  sku                 = "Standard"
  allocation_method   = "Static"
}

####################################################
# spokes
####################################################

# spoke1
#----------------------------

resource "azurerm_public_ip" "spoke1_appgw_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.spoke1_prefix}appgw-pip"
  location            = local.spoke1_location
  allocation_method   = "Static"
  sku                 = "Standard"
}

####################################################
# branches
####################################################

# branch1
#----------------------------

resource "azurerm_public_ip" "branch1_nva_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch1_prefix}nva-pip"
  location            = local.region1
  sku                 = "Standard"
  allocation_method   = "Static"
}

# branch2
#----------------------------

resource "azurerm_public_ip" "branch2_nva_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch2_prefix}nva-pip"
  location            = local.region1
  sku                 = "Standard"
  allocation_method   = "Static"
}

# branch3
#----------------------------

resource "azurerm_public_ip" "branch3_nva_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch3_prefix}nva-pip"
  location            = local.region2
  sku                 = "Standard"
  allocation_method   = "Static"
}

# branch4
#----------------------------

resource "azurerm_public_ip" "branch4_nva_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch4_prefix}nva-pip"
  location            = local.region2
  sku                 = "Standard"
  allocation_method   = "Static"
}
