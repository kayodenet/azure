
####################################################
# providers
####################################################

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

# default resource group

resource "azurerm_resource_group" "rg" {
  name     = "${local.prefix}RG"
  location = local.default_region
}

# my public ip

data "http" "mypip" {
  url = "http://ipv4.icanhazip.com"
}

####################################################
# nsg
####################################################

# region1
#----------------------------

# vm

resource "azurerm_network_security_group" "nsg_region1_main" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.prefix}-nsg-${local.region1}-main"
  location            = local.region1
}

resource "azurerm_network_security_rule" "nsg_region1_main_inbound_allow_all" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_region1_main.name
  name                        = "inbound-allow-all"
  direction                   = "Inbound"
  access                      = "Allow"
  priority                    = 100
  source_address_prefixes     = local.rfc1918_prefixes
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  protocol                    = "*"
  description                 = "Inbound Allow RFC1918"
}

resource "azurerm_network_security_rule" "nsg_region1_main_outbound_allow_rfc1918" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_region1_main.name
  name                        = "outbound-allow-rfc1918"
  direction                   = "Outbound"
  access                      = "Allow"
  priority                    = 100
  source_address_prefixes     = local.rfc1918_prefixes
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  protocol                    = "*"
  description                 = "Outbound Allow RFC1918"
}

####################################################
# storage accounts (boot diagnostics)
####################################################

resource "random_id" "storage_accounts" {
  byte_length = 4
}

# region 1

resource "azurerm_storage_account" "region1" {
  resource_group_name      = azurerm_resource_group.rg.name
  name                     = lower("${local.prefix}region1${random_id.storage_accounts.hex}")
  location                 = local.region1
  account_replication_type = "LRS"
  account_tier             = "Standard"
}

