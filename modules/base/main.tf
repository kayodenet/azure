
# vnet
#----------------------------

resource "azurerm_virtual_network" "this" {
  resource_group_name = var.resource_group
  name                = "${var.name}vnet"
  address_space       = var.vnet_config[0].address_space
  location            = var.location
}

# dns
#----------------------------

resource "azurerm_private_dns_zone" "this" {
  count               = var.private_dns_zone == null ? 0 : 1
  resource_group_name = var.resource_group
  name                = var.private_dns_zone
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  count                 = var.private_dns_zone == null ? 0 : 1
  resource_group_name   = var.resource_group
  name                  = "${var.name}vnet"
  private_dns_zone_name = azurerm_private_dns_zone.this[0].name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = true
}

resource "azurerm_private_dns_zone_virtual_network_link" "external" {
  for_each              = toset(var.dns_zone_linked_vnets)
  resource_group_name   = var.resource_group
  name                  = split("/", each.value)[8]
  private_dns_zone_name = azurerm_private_dns_zone.this[0].name
  virtual_network_id    = each.value
  registration_enabled  = false
}

resource "azurerm_private_dns_resolver_virtual_network_link" "external" {
  for_each                  = toset(var.dns_zone_linked_rulesets)
  name                      = "${var.name}-${split("/", each.value)[8]}-link"
  dns_forwarding_ruleset_id = each.value
  virtual_network_id        = azurerm_virtual_network.this.id
}


# subnets
#----------------------------

resource "azurerm_subnet" "this" {
  for_each             = var.vnet_config[0].subnets
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.this.name
  name                 = each.key
  address_prefixes     = each.value.address_prefixes

  dynamic "delegation" {
    iterator = delegation
    for_each = contains(try(each.value.delegate, []), "dns") ? [1] : []
    content {
      name = "Microsoft.Network.dnsResolvers"
      service_delegation {
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        name    = "Microsoft.Network/dnsResolvers"
      }
    }
  }
}

/*# nsg
#----------------------------

resource "azurerm_subnet_network_security_group_association" "main" {
  for_each                  = { for k, v in var.vnet_config[0].subnets : k => v if length(regexall("main", k)) > 0 && var.network_security_group_id_main != null }
  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = var.network_security_group_id_main
}

resource "azurerm_subnet_network_security_group_association" "appgw" {
  for_each                  = { for k, v in var.vnet_config[0].subnets : k => v if length(regexall("appgw", k)) > 0 && var.network_security_group_id_appgw != null }
  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = var.network_security_group_id_appgw
}

resource "azurerm_subnet_network_security_group_association" "int" {
  for_each                  = { for k, v in var.vnet_config[0].subnets : k => v if length(regexall("int", k)) > 0 && var.network_security_group_id_int != null }
  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = var.network_security_group_id_int
}

resource "azurerm_subnet_network_security_group_association" "ext" {
  for_each                  = { for k, v in var.vnet_config[0].subnets : k => v if length(regexall("ext", k)) > 0 && var.network_security_group_id_ext != null }
  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = var.network_security_group_id_ext
}*/

# dns
#----------------------------

module "dns" {
  count            = length(var.dns_config) == 0 ? 0 : 1
  source           = "../../modules/debian"
  resource_group   = var.resource_group
  name             = "${var.name}dns"
  location         = var.location
  subnet           = [for k, v in azurerm_subnet.this : v.id if length(regexall("main", k)) > 0][0]
  private_ip       = var.dns_config[0].private_ip
  use_vm_extension = var.dns_config[0].use_vm_extension
  custom_data      = var.dns_config[0].custom_data
  enable_public_ip = var.dns_config[0].public_ip == null ? false : true
  storage_account  = var.storage_account
  admin_username   = var.admin_username
  admin_password   = var.admin_password
}

# vm
#----------------------------

module "vm" {
  source           = "../../modules/ubuntu"
  resource_group   = var.resource_group
  name             = "${var.name}vm"
  location         = var.location
  subnet           = [for k, v in azurerm_subnet.this : v.id if length(regexall("main", k)) > 0][0]
  private_ip       = var.vm_config[0].private_ip
  use_vm_extension = var.vm_config[0].use_vm_extension
  custom_data      = var.vm_config[0].custom_data
  enable_public_ip = var.vm_config[0].public_ip == null ? false : true
  dns_servers      = var.vnet_config[0].dns_servers
  storage_account  = var.storage_account
  admin_username   = var.admin_username
  admin_password   = var.admin_password
  private_dns_zone = try(azurerm_private_dns_zone.this[0].name, "")
  dns_host         = var.vm_config[0].dns_host
}

# nat
#----------------------------

resource "azurerm_public_ip" "nat" {
  count               = length(var.vnet_config[0].subnets_nat_gateway) == 0 ? 0 : 1
  resource_group_name = var.resource_group
  name                = "${var.name}natgw"
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat" {
  count               = length(var.vnet_config[0].subnets_nat_gateway) == 0 ? 0 : 1
  resource_group_name = var.resource_group
  name                = "${var.name}natgw"
  location            = var.location
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat" {
  count                = length(var.vnet_config[0].subnets_nat_gateway) == 0 ? 0 : 1
  nat_gateway_id       = azurerm_nat_gateway.nat[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

resource "azurerm_subnet_nat_gateway_association" "nat" {
  for_each       = toset(var.vnet_config[0].subnets_nat_gateway)
  subnet_id      = azurerm_subnet.this[each.key].id
  nat_gateway_id = azurerm_nat_gateway.nat[0].id
}


# resolver
#----------------------------

resource "azurerm_private_dns_resolver" "this" {
  count               = var.vnet_config[0].enable_private_dns_resolver ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${var.name}dns-resolver"
  location            = var.location
  virtual_network_id  = azurerm_virtual_network.this.id
}

# endpoints
#----------------------------

resource "azurerm_private_dns_resolver_inbound_endpoint" "this" {
  count                   = var.vnet_config[0].enable_private_dns_resolver ? 1 : 0
  name                    = "${var.name}dns-in"
  private_dns_resolver_id = azurerm_private_dns_resolver.this[0].id
  location                = var.location
  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = [for k, v in azurerm_subnet.this : v.id if length(regexall("dns-in", k)) > 0][0]
  }
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "this" {
  count                   = var.vnet_config[0].enable_private_dns_resolver ? 1 : 0
  name                    = "${var.name}dns-out"
  private_dns_resolver_id = azurerm_private_dns_resolver.this[0].id
  location                = var.location
  subnet_id               = [for k, v in azurerm_subnet.this : v.id if length(regexall("dns-out", k)) > 0][0]
}
