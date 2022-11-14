
# common
#----------------------------

terraform {
  required_providers {
    megaport = {
      source  = "megaport/megaport"
      version = "0.1.9"
    }
  }
}

provider "megaport" {
  username              = var.megaport_username
  password              = var.megaport_password
  accept_purchase_terms = true
  delete_ports          = true
  environment           = "production"
}

variable "megaport_username" {
  description = "megaport username"
}

variable "megaport_password" {
  description = "megaport password"
}

data "megaport_location" "location" {
  name    = "Equinix AM1"
  has_mcr = true
}

# er circuit
#----------------------------

# bu1

resource "azurerm_express_route_circuit" "er_circuit_bu1" {
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = "${local.bu1_prefix}hub-local-gw0"
  location              = local.bu1_location
  service_provider_name = "Megaport"
  peering_location      = "Amsterdam"
  bandwidth_in_mbps     = 50
  sku {
    tier   = "Standard"
    family = "MeteredData"
  }
}

resource "azurerm_express_route_circuit_authorization" "er_circuit_bu1" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.bu1_prefix}hub-local-gw0"
  express_route_circuit_name = azurerm_express_route_circuit.er_circuit_bu1.name
}

# branch1

resource "azurerm_express_route_circuit" "er_circuit_branch1" {
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = "${local.branch1_prefix}hub-local-gw0"
  location              = local.branch1_location
  service_provider_name = "Megaport"
  peering_location      = "Amsterdam"
  bandwidth_in_mbps     = 50
  sku {
    tier   = "Standard"
    family = "MeteredData"
  }
}

resource "azurerm_express_route_circuit_authorization" "er_circuit_branch1" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.branch1_prefix}hub-local-gw0"
  express_route_circuit_name = azurerm_express_route_circuit.er_circuit_branch1.name
}

# mcr
#----------------------------

resource "megaport_mcr" "megaport_mcr" {
  mcr_name    = "${local.megaport_prefix}-mcr"
  location_id = data.megaport_location.location.id
  router {
    port_speed    = 1000
    requested_asn = local.megaport_asn
  }
}

# megaport connection
#----------------------------

# bu1

resource "megaport_azure_connection" "azure_vcx_bu1" {
  vxc_name   = "${local.megaport_prefix}-azure-vcx-bu1"
  rate_limit = 50
  a_end {
    requested_vlan = local.megaport_bu1_vlan
  }
  csp_settings {
    service_key = azurerm_express_route_circuit.er_circuit_bu1.service_key
    attached_to = megaport_mcr.megaport_mcr.id
    peerings {
      private_peer   = true
      microsoft_peer = false
    }
  }
}

# branch1

resource "megaport_azure_connection" "azure_vcx_branch1" {
  vxc_name   = "${local.megaport_prefix}-azure-vcx-branch1"
  rate_limit = 50
  a_end {
    requested_vlan = local.megaport_branch1_vlan
  }
  csp_settings {
    service_key = azurerm_express_route_circuit.er_circuit_branch1.service_key
    attached_to = megaport_mcr.megaport_mcr.id
    peerings {
      private_peer   = true
      microsoft_peer = false
    }
  }
}

# gateway connection
#----------------------------

# bu1

resource "azurerm_virtual_network_gateway_connection" "azure_vcx_bu1" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.bu1_prefix}-azure-vcx-bu1"
  location                   = local.bu1_location
  type                       = "ExpressRoute"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.bu1_ergw.id
  authorization_key          = azurerm_express_route_circuit_authorization.er_circuit_bu1.authorization_key
  express_route_circuit_id   = azurerm_express_route_circuit.er_circuit_bu1.id
  depends_on = [
    megaport_azure_connection.azure_vcx_bu1
  ]
}

# branch1

resource "azurerm_virtual_network_gateway_connection" "azure_vcx_branch1" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.branch1_prefix}-azure-vcx-branch1"
  location                   = local.branch1_location
  type                       = "ExpressRoute"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.branch1_ergw.id
  authorization_key          = azurerm_express_route_circuit_authorization.er_circuit_branch1.authorization_key
  express_route_circuit_id   = azurerm_express_route_circuit.er_circuit_branch1.id
  depends_on = [
    megaport_azure_connection.azure_vcx_branch1
  ]
}
