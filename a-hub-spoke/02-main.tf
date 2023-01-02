
# vm startup scripts
#----------------------------

locals {
  prefix = "AX"

  hub1_nva_asn   = "65000"
  hub1_vpngw_asn = "65515"
  hub1_ergw_asn  = "65515"
  hub1_ars_asn   = "65515"

  hub2_nva_asn   = "65000"
  hub2_vpngw_asn = "65515"
  hub2_ergw_asn  = "65515"
  hub2_ars_asn   = "65515"
  mypip          = chomp(data.http.mypip.response_body)

  vm_script_targets = [
    { name = "branch1", dns = local.branch1_vm_dns, ip = local.branch1_vm_addr },
    { name = "branch2", dns = local.branch2_vm_dns, ip = local.branch2_vm_addr },
    { name = "branch3", dns = local.branch3_vm_dns, ip = local.branch3_vm_addr },
    { name = "hub1   ", dns = local.hub1_vm_dns, ip = local.hub1_vm_addr },
    { name = "hub2   ", dns = local.hub2_vm_dns, ip = local.hub2_vm_addr },
    { name = "spoke1 ", dns = local.spoke1_vm_dns, ip = local.spoke1_vm_addr },
    { name = "spoke2 ", dns = local.spoke2_vm_dns, ip = local.spoke2_vm_addr },
    { name = "spoke3 ", dns = local.spoke3_vm_dns, ip = local.spoke3_vm_addr, sandbox = true },
    { name = "spoke4 ", dns = local.spoke4_vm_dns, ip = local.spoke4_vm_addr },
    { name = "spoke5 ", dns = local.spoke5_vm_dns, ip = local.spoke5_vm_addr },
    { name = "spoke6 ", dns = local.spoke6_vm_dns, ip = local.spoke6_vm_addr, sandbox = true },
  ]
  vm_startup = templatefile("../scripts/server.sh", {
    TARGETS = local.vm_script_targets
  })
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

