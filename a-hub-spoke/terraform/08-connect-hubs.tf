
####################################################
# inter-hub
####################################################

# hub1-to-hub2

resource "azurerm_virtual_network_peering" "hub1_to_hub2_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub1-to-hub2-peering"
  virtual_network_name         = azurerm_virtual_network.hub1_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.hub2_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# hub2-to-hub1

resource "azurerm_virtual_network_peering" "hub2_to_hub1_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub2-to-hub1-peering"
  virtual_network_name         = azurerm_virtual_network.hub2_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.hub1_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}
