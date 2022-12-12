
output "vnet" {
  value = azurerm_virtual_network.this
}

output "subnets" {
  value = azurerm_subnet.this
}

output "private_dns_zone" {
  value = azurerm_private_dns_zone.this
}

output "private_dns_inbound_ep" {
  value = try(azurerm_private_dns_resolver_inbound_endpoint.this[0], {})
}

output "private_dns_outbound_ep" {
  value = try(azurerm_private_dns_resolver_outbound_endpoint.this[0], {})
}
