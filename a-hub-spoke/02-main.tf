
# vm startup scripts
#----------------------------

locals {
  prefix = "A"

  hub1_nva_asn   = "65000"
  hub1_vpngw_asn = "65515"
  hub1_ergw_asn  = "65515"
  hub1_ars_asn   = "65515"

  hub2_nva_asn   = "65000"
  hub2_vpngw_asn = "65515"
  hub2_ergw_asn  = "65515"
  hub2_ars_asn   = "65515"
  #mypip          = chomp(data.http.mypip.response_body)
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

resource "azurerm_public_ip" "hub1_ergw_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}ergw-pip"
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

# nva

resource "azurerm_public_ip" "branch1_nva_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch1_prefix}nva-pip"
  location            = local.region1
  sku                 = "Standard"
  allocation_method   = "Static"
}

# branch2
#----------------------------

# nva

resource "azurerm_public_ip" "branch2_nva_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch2_prefix}nva-pip"
  location            = local.region1
  sku                 = "Standard"
  allocation_method   = "Static"
}

# ergw

resource "azurerm_public_ip" "branch2_ergw_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch2_prefix}ergw-pip"
  location            = local.region1
  sku                 = "Standard"
  allocation_method   = "Static"
}

# branch3
#----------------------------

# nva

resource "azurerm_public_ip" "branch3_nva_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch3_prefix}nva-pip"
  location            = local.region2
  sku                 = "Standard"
  allocation_method   = "Static"
}

# branch4
#----------------------------

# nva

resource "azurerm_public_ip" "branch4_nva_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch4_prefix}nva-pip"
  location            = local.region2
  sku                 = "Standard"
  allocation_method   = "Static"
}
