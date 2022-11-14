
# Common
#----------------------------
locals {
  region1  = "westeurope"
  region2  = "northeurope"
  username = "azureuser"
  password = "Password123"
  vmsize   = "Standard_DS1_v2"
  psk      = "changeme"

  default_region      = "westeurope"
  subnets_without_nsg = ["GatewaySubnet"]

  rfc1918_prefixes = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

# hub
#----------------------------

locals {
  ecs_prefix        = local.prefix == "" ? "hub-" : join("-", [local.prefix, "hub-"])
  ecs_location      = local.region1
  ecs_vpngw_asn     = "65011"
  ecs_address_space = ["10.11.0.0/16"]
  ecs_domain        = "hub"
  ecs_tags          = { env = "hub" }
  ecs_subnets = {
    ("${local.ecs_prefix}main") = { address_prefixes = ["10.11.0.0/24"] }
    ("${local.ecs_prefix}bu1")  = { address_prefixes = ["10.11.1.0/24"] }
    ("${local.ecs_prefix}bu2")  = { address_prefixes = ["10.11.2.0/24"] }
    ("GatewaySubnet")           = { address_prefixes = ["10.11.3.0/24"] }
  }
  ecs_default_gw_main = cidrhost(local.ecs_subnets["${local.ecs_prefix}main"].address_prefixes[0], 1)
  ecs_main_vm_addr    = cidrhost(local.ecs_subnets["${local.ecs_prefix}main"].address_prefixes[0], 5)
  ecs_bu1_vm_addr     = cidrhost(local.ecs_subnets["${local.ecs_prefix}bu1"].address_prefixes[0], 5)
  ecs_bu2_vm_addr     = cidrhost(local.ecs_subnets["${local.ecs_prefix}bu2"].address_prefixes[0], 5)
  ecs_vpngw_bgp_ip    = cidrhost(local.ecs_subnets["GatewaySubnet"].address_prefixes[0], 254)
}

# bu1
#----------------------------

locals {
  bu1_prefix        = local.prefix == "" ? "bu1-" : join("-", [local.prefix, "bu1-"])
  bu1_location      = local.region1
  bu1_vpngw_asn     = "65515"
  bu1_address_space = ["10.1.0.0/16"]
  bu1_domain        = "bu1.azure"
  bu1_tags          = { env = "bu1" }
  bu1_subnets = {
    ("${local.bu1_prefix}main") = { address_prefixes = ["10.1.0.0/24"] }
    ("GatewaySubnet")           = { address_prefixes = ["10.1.1.0/24"] }
    ("RouteServerSubnet")       = { address_prefixes = ["10.1.2.0/24"] }
  }
  bu1_vm_addr      = cidrhost(local.bu1_subnets["${local.bu1_prefix}main"].address_prefixes[0], 5)
  bu1_vpngw_bgp_ip = cidrhost(local.bu1_subnets["GatewaySubnet"].address_prefixes[0], 254)
  bu1_vm_dns       = "vm.${local.bu1_domain}"
}

# bu2
#----------------------------

locals {
  bu2_prefix        = local.prefix == "" ? "bu2-" : join("-", [local.prefix, "bu2-"])
  bu2_location      = local.region1
  bu2_vpngw_asn     = "65515"
  bu2_address_space = ["10.2.0.0/16"]
  bu2_domain        = "bu2.azure"
  bu2_tags          = { env = "bu2" }
  bu2_subnets = {
    ("${local.bu2_prefix}main") = { address_prefixes = ["10.2.0.0/24"] }
    ("GatewaySubnet")           = { address_prefixes = ["10.2.1.0/24"] }
    ("RouteServerSubnet")       = { address_prefixes = ["10.2.2.0/24"] }
  }
  bu2_vm_addr      = cidrhost(local.bu2_subnets["${local.bu2_prefix}main"].address_prefixes[0], 5)
  bu2_vpngw_bgp_ip = cidrhost(local.bu2_subnets["GatewaySubnet"].address_prefixes[0], 254)
  bu2_vm_dns       = "vm.${local.bu2_domain}"
}

# branch1
#----------------------------

locals {
  branch1_prefix        = local.prefix == "" ? "branch1-" : join("-", [local.prefix, "branch1-"])
  branch1_location      = local.region1
  branch1_address_space = ["10.10.0.0/16"]
  branch1_domain        = "branch1"
  branch1_tags          = { env = "branch1" }
  branch1_subnets = {
    ("${local.branch1_prefix}main") = { address_prefixes = ["10.10.0.0/24"] }
    ("GatewaySubnet")               = { address_prefixes = ["10.10.1.0/24"] }
  }
  branch1_vm_addr = cidrhost(local.branch1_subnets["${local.branch1_prefix}main"].address_prefixes[0], 5)
  branch1_vm_dns  = "vm.${local.branch1_domain}"
}

# branch2
#----------------------------

locals {
  branch2_prefix        = local.prefix == "" ? "branch2-" : join("-", [local.prefix, "branch2-"])
  branch2_location      = local.region1
  branch2_address_space = ["10.20.0.0/16"]
  branch2_nva_asn       = "65002"
  branch2_domain        = "branch2"
  branch2_tags          = { env = "branch2" }
  branch2_subnets = {
    ("${local.branch2_prefix}main") = { address_prefixes = ["10.20.0.0/24"] }
    ("${local.branch2_prefix}ext")  = { address_prefixes = ["10.20.1.0/24"] }
    ("${local.branch2_prefix}int")  = { address_prefixes = ["10.20.2.0/24"] }
  }
  branch2_ext_default_gw = cidrhost(local.branch2_subnets["${local.branch2_prefix}ext"].address_prefixes[0], 1)
  branch2_int_default_gw = cidrhost(local.branch2_subnets["${local.branch2_prefix}int"].address_prefixes[0], 1)
  branch2_nva_ext_addr   = cidrhost(local.branch2_subnets["${local.branch2_prefix}ext"].address_prefixes[0], 9)
  branch2_nva_int_addr   = cidrhost(local.branch2_subnets["${local.branch2_prefix}int"].address_prefixes[0], 9)
  branch2_vm_addr        = cidrhost(local.branch2_subnets["${local.branch2_prefix}main"].address_prefixes[0], 5)
  branch2_nva_loopback0  = "192.168.20.20"
  branch2_nva_tun_range0 = "10.20.20.0/30"
  branch2_nva_tun_range1 = "10.20.20.4/30"
  branch2_vm_dns         = "vm.${local.branch2_domain}"
}

# megaport
#----------------------------
locals {
  megaport_prefix       = "salawu"
  megaport_asn          = 65111
  megaport_bu1_vlan     = "100"
  megaport_branch1_vlan = "110"
}
