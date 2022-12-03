
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

# log analytics workspace

resource "azurerm_log_analytics_workspace" "analytics_ws" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.prefix}analytics-ws"
  location            = local.default_region
  sku                 = "PerGB2018"
  retention_in_days   = 30
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

resource "azurerm_network_security_rule" "nsg_region1_main_inbound_allow_tcp_mypip" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_region1_main.name
  name                        = "inbound-allow-tcp-mypip"
  direction                   = "Inbound"
  access                      = "Allow"
  priority                    = 110
  source_address_prefix       = local.mypip
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  protocol                    = "Tcp"
  description                 = "Allow inbound SSH"
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

# nva

resource "azurerm_network_security_group" "nsg_region1_nva" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.prefix}-nsg-${local.region1}-nva"
  location            = local.region1
}

resource "azurerm_network_security_rule" "nsg_region1_nva_inbound_allow_rfc1918" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_region1_nva.name
  name                        = "inbound-allow-rfc1918"
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

resource "azurerm_network_security_rule" "nsg_region1_nva_outbound_allow_rfc1918" {
  resource_group_name          = azurerm_resource_group.rg.name
  network_security_group_name  = azurerm_network_security_group.nsg_region1_nva.name
  name                         = "outbound-allow-rfc1918"
  direction                    = "Outbound"
  access                       = "Allow"
  priority                     = 100
  source_address_prefix        = "*"
  source_port_range            = "*"
  destination_address_prefixes = local.rfc1918_prefixes
  destination_port_range       = "*"
  protocol                     = "*"
  description                  = "Outbound Allow RFC1918"
}

resource "azurerm_network_security_rule" "nsg_region1_nva_inbound_allow_ipsec" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_region1_nva.name
  name                        = "inbound-allow-ipsec"
  direction                   = "Inbound"
  access                      = "Allow"
  priority                    = 110
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_ranges     = ["500", "4500"]
  protocol                    = "Udp"
  description                 = "Inbound Allow UDP 500, 4500"
}

resource "azurerm_network_security_rule" "nsg_region1_nva_outbound_allow_ipsec" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_region1_nva.name
  name                        = "outbound-allow-ipsec"
  direction                   = "Outbound"
  access                      = "Allow"
  priority                    = 110
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_ranges     = ["500", "4500"]
  protocol                    = "Udp"
  description                 = "Outbound Allow UDP 500, 4500"
}

# appgw

resource "azurerm_network_security_group" "nsg_region1_appgw" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.prefix}-nsg-${local.region1}-appgw"
  location            = local.region1
}

resource "azurerm_network_security_rule" "nsg_region1_nva_inbound_allow_appgw_v2sku" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_region1_appgw.name
  name                        = "inbound-allow-appgw-v2sku"
  direction                   = "Inbound"
  access                      = "Allow"
  priority                    = 100
  source_address_prefix       = "GatewayManager"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "65200-65535"
  protocol                    = "*"
  description                 = "Allow Inbound Azure infrastructure communication"
}

# region2
#----------------------------

# vm

resource "azurerm_network_security_group" "nsg_region2_main" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.prefix}-nsg-${local.region2}-main"
  location            = local.region2
}

resource "azurerm_network_security_rule" "nsg_region2_main_inbound_allow_rfc1918" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_region2_main.name
  name                        = "inbound-allow-rfc1918"
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

resource "azurerm_network_security_rule" "nsg_region2_main_outbound_allow_rfc1918" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_region2_main.name
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

# nva

resource "azurerm_network_security_group" "nsg_region2_nva" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.prefix}-nsg-${local.region2}-nva"
  location            = local.region2
}

resource "azurerm_network_security_rule" "nsg_region2_nva_inbound_allow_rfc1918" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_region2_nva.name
  name                        = "inbound-allow-rfc1918"
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

resource "azurerm_network_security_rule" "nsg_region2_nva_outbound_allow_rfc1918" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_region2_nva.name
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

resource "azurerm_network_security_rule" "nsg_region2_nva_inbound_allow_ipsec" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_region2_nva.name
  name                        = "inbound-allow-ipsec"
  direction                   = "Inbound"
  access                      = "Allow"
  priority                    = 110
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_ranges     = ["500", "4500"]
  protocol                    = "Udp"
  description                 = "Inbound Allow UDP 500, 4500"
}

resource "azurerm_network_security_rule" "nsg_region2_nva_outbound_allow_ipsec" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_region2_nva.name
  name                        = "outbound-allow-ipsec"
  direction                   = "Outbound"
  access                      = "Allow"
  priority                    = 110
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_ranges     = ["500", "4500"]
  protocol                    = "Udp"
  description                 = "Outbound Allow UDP 500, 4500"
}

# appgw

resource "azurerm_network_security_group" "nsg_region2_appgw" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.prefix}-nsg-${local.region2}-appgw"
  location            = local.region2
}

resource "azurerm_network_security_rule" "nsg_region2_nva_inbound_allow_appgw_v2sku" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_region2_appgw.name
  name                        = "inbound-allow-appgw-v2sku"
  direction                   = "Inbound"
  access                      = "Allow"
  priority                    = 100
  source_address_prefix       = "GatewayManager"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "65200-65535"
  protocol                    = "*"
  description                 = "Allow Inbound Azure infrastructure communication"
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

# region 2

resource "azurerm_storage_account" "region2" {
  resource_group_name      = azurerm_resource_group.rg.name
  name                     = lower("${local.prefix}region2${random_id.storage_accounts.hex}")
  location                 = local.region2
  account_replication_type = "LRS"
  account_tier             = "Standard"
}

####################################################
# sleep
####################################################

resource "time_sleep" "time_60" {
  create_duration = "60s"
}

resource "time_sleep" "time_120" {
  create_duration = "60s"
}

####################################################
# dns
####################################################

resource "azurerm_private_dns_zone" "azure" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "az.salawu.net"
}
