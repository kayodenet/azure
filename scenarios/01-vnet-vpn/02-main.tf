
# vm startup scripts
#----------------------------

locals {
  prefix = "SapVpn"
  mypip  = chomp(data.http.mypip.response_body)
  vm_startup = templatefile("../../scripts/vm.sh", {
    TARGETS_IP = [
      local.ecs_main_vm_addr,
      local.ecs_bu1_vm_addr,
      local.ecs_bu2_vm_addr,
      local.bu1_vm_addr,
      local.bu2_vm_addr,
      local.branch1_vm_addr,
    ]
    TARGETS_DNS = []
  })
}

####################################################
# ecs environment
####################################################

# ecs
#----------------------------

# vpngw

resource "azurerm_public_ip" "ecs_vpngw_pip0" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.ecs_prefix}vpngw-pip0"
  location            = local.region1
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "ecs_vpngw_pip1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.ecs_prefix}vpngw-pip1"
  location            = local.region1
  sku                 = "Standard"
  allocation_method   = "Static"
}

####################################################
# business units
####################################################

# bu1
#----------------------------

# vpngw

resource "azurerm_public_ip" "bu1_vpngw_pip0" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.bu1_prefix}vpngw-pip0"
  location            = local.region1
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "bu1_vpngw_pip1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.bu1_prefix}vpngw-pip1"
  location            = local.region1
  sku                 = "Standard"
  allocation_method   = "Static"
}

# ergw

resource "azurerm_public_ip" "bu1_ergw_pip0" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.bu1_prefix}ergw-pip0"
  location            = local.region1
  sku                 = "Standard"
  allocation_method   = "Static"
}

# ars

resource "azurerm_public_ip" "bu1_ars_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.bu1_prefix}ars-pip"
  location            = local.region1
  sku                 = "Standard"
  allocation_method   = "Static"
}

# bu2
#----------------------------

# vpngw

resource "azurerm_public_ip" "bu2_vpngw_pip0" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.bu2_prefix}vpngw-pip0"
  location            = local.region1
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "bu2_vpngw_pip1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.bu2_prefix}vpngw-pip1"
  location            = local.region1
  sku                 = "Standard"
  allocation_method   = "Static"
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

# ergw

resource "azurerm_public_ip" "branch1_ergw_pip0" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch1_prefix}ergw-pip0"
  location            = local.region1
  sku                 = "Standard"
  allocation_method   = "Static"
}
