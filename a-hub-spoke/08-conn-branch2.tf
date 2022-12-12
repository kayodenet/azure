
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

# hub1

resource "azurerm_express_route_circuit" "hub1_er_circuit" {
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = "${local.hub1_prefix}er-circuit"
  location              = local.hub1_location
  service_provider_name = "Megaport"
  peering_location      = "Amsterdam"
  bandwidth_in_mbps     = 50
  sku {
    tier   = "Standard"
    family = "MeteredData"
  }
}

resource "azurerm_express_route_circuit_authorization" "hub1_er_circuit" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub1_prefix}er-circuit"
  express_route_circuit_name = azurerm_express_route_circuit.hub1_er_circuit.name
}

# branch2

resource "azurerm_express_route_circuit" "branch2_er_circuit" {
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = "${local.branch2_prefix}er-circuit"
  location              = local.branch2_location
  service_provider_name = "Megaport"
  peering_location      = "Amsterdam"
  bandwidth_in_mbps     = 50
  sku {
    tier   = "Standard"
    family = "MeteredData"
  }
}

resource "azurerm_express_route_circuit_authorization" "branch2_er_circuit" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.branch2_prefix}er-circuit"
  express_route_circuit_name = azurerm_express_route_circuit.branch2_er_circuit.name
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

# megaport connection (private peering)
#----------------------------

# hub1

resource "megaport_azure_connection" "azure_vcx_hub1" {
  vxc_name   = "${local.megaport_prefix}-azure-vcx-hub1"
  rate_limit = 50
  a_end {
    requested_vlan = local.megaport_hub1_vlan
  }
  csp_settings {
    service_key = azurerm_express_route_circuit.hub1_er_circuit.service_key
    attached_to = megaport_mcr.megaport_mcr.id
    peerings {
      private_peer   = true
      microsoft_peer = false
    }
  }
}

# branch2

resource "megaport_azure_connection" "azure_vcx_branch2" {
  vxc_name   = "${local.megaport_prefix}-azure-vcx-branch2"
  rate_limit = 50
  a_end {
    requested_vlan = local.megaport_branch2_vlan
  }
  csp_settings {
    service_key = azurerm_express_route_circuit.branch2_er_circuit.service_key
    attached_to = megaport_mcr.megaport_mcr.id
    peerings {
      private_peer   = true
      microsoft_peer = false
    }
  }
}

# gateway connection
#----------------------------

# hub1

resource "azurerm_virtual_network_gateway_connection" "azure_vcx_hub1" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub1_prefix}-azure-vcx-hub1"
  location                   = local.hub1_location
  type                       = "ExpressRoute"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.hub1_ergw.id
  authorization_key          = azurerm_express_route_circuit_authorization.hub1_er_circuit.authorization_key
  express_route_circuit_id   = azurerm_express_route_circuit.hub1_er_circuit.id
  depends_on = [
    megaport_azure_connection.azure_vcx_hub1
  ]
}

# branch2

resource "azurerm_virtual_network_gateway_connection" "azure_vcx_branch2" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.branch2_prefix}-azure-vcx-branch2"
  location                   = local.branch2_location
  type                       = "ExpressRoute"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.branch2_ergw.id
  authorization_key          = azurerm_express_route_circuit_authorization.branch2_er_circuit.authorization_key
  express_route_circuit_id   = azurerm_express_route_circuit.branch2_er_circuit.id
  depends_on = [
    megaport_azure_connection.azure_vcx_branch2
  ]
}
