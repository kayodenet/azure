
# Common
#----------------------------
locals {
  region1  = "westeurope"
  region2  = "northeurope"
  username = "azureuser"
  password = "Password123"
  vmsize   = "Standard_DS1_v2"
  psk      = "changeme"

  bgp_apipa_range1 = "169.254.21.0/30"
  bgp_apipa_range2 = "169.254.21.4/30"
  bgp_apipa_range3 = "169.254.21.8/30"
  bgp_apipa_range4 = "169.254.21.12/30"
  bgp_apipa_range5 = "169.254.21.16/30"
  bgp_apipa_range6 = "169.254.21.20/30"
  bgp_apipa_range7 = "169.254.21.24/30"
  bgp_apipa_range8 = "169.254.21.28/30"

  default_region      = "westeurope"
  subnets_without_nsg = ["GatewaySubnet"]

  onprem_domain = "salawu.net"
  cloud_domain  = "az.salawu.net"

  rfc1918_prefixes = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]

  vm_script_targets = [
    { name = "branch1", dns = local.branch1_vm_dns, ip = local.branch1_vm_addr },
    { name = "branch2", dns = local.branch2_vm_dns, ip = local.branch2_vm_addr },
    { name = "branch3", dns = local.branch3_vm_dns, ip = local.branch3_vm_addr },
    #{ name = "branch4", dns = local.branch4_vm_dns, ip = local.branch4_vm_addr },
    { name = "hub1   ", dns = local.hub1_vm_dns, ip = local.hub1_vm_addr },
    { name = "hub2   ", dns = local.hub2_vm_dns, ip = local.hub2_vm_addr },
    { name = "spoke1 ", dns = local.spoke1_vm_dns, ip = local.spoke1_vm_addr },
    { name = "spoke2 ", dns = local.spoke2_vm_dns, ip = local.spoke2_vm_addr },
    { name = "spoke3 ", dns = local.spoke3_vm_dns, ip = local.spoke3_vm_addr },
    { name = "spoke4 ", dns = local.spoke4_vm_dns, ip = local.spoke4_vm_addr },
    { name = "spoke5 ", dns = local.spoke5_vm_dns, ip = local.spoke5_vm_addr },
    { name = "spoke6 ", dns = local.spoke6_vm_dns, ip = local.spoke6_vm_addr },
  ]

  vm_startup = templatefile("../scripts/server.sh", {
    TARGETS = local.vm_script_targets
  })

  branch_unbound_config = templatefile("../scripts/unbound.sh", {
    ONPREM_LOCAL_RECORDS = local.onprem_local_records
    REDIRECTED_HOSTS     = local.onprem_redirected_hosts
    FORWARD_ZONES        = local.onprem_forward_zones
    TARGETS              = local.vm_script_targets
  })

  branch_unbound_vars = {
    ONPREM_LOCAL_RECORDS = local.onprem_local_records
    REDIRECTED_HOSTS     = local.onprem_redirected_hosts
    FORWARD_ZONES        = local.onprem_forward_zones
    TARGETS              = local.vm_script_targets
  }


  onprem_local_records = [
    { name = (local.branch1_vm_dns), record = local.branch1_vm_addr },
    { name = (local.branch2_vm_dns), record = local.branch2_vm_addr },
    { name = (local.branch3_vm_dns), record = local.branch3_vm_addr },
    { name = (local.branch4_vm_dns), record = local.branch4_vm_addr },
  ]
  onprem_forward_zones = [
    { zone = "${local.cloud_domain}.", targets = [local.hub1_dns_in_addr, ] },
    { zone = ".", targets = ["168.63.129.16"] },
  ]
  onprem_redirected_hosts = []
}

# vhub1
#----------------------------

locals {
  vhub1_prefix            = local.prefix == "" ? "vhub1-" : join("-", [local.prefix, "vhub1-"])
  vhub1_location          = local.region1
  vhub1_bgp_asn           = "65515"
  vhub1_address_prefix    = "192.168.11.0/24"
  vhub1_vpngw_bgp_apipa_0 = cidrhost(local.bgp_apipa_range1, 1)
  vhub1_vpngw_bgp_apipa_1 = cidrhost(local.bgp_apipa_range2, 1)
}

# vhub2
#----------------------------

locals {
  vhub2_prefix            = local.prefix == "" ? "vhub2-" : join("-", [local.prefix, "vhub2-"])
  vhub2_location          = local.region2
  vhub2_bgp_asn           = "65515"
  vhub2_address_prefix    = "192.168.22.0/24"
  vhub2_vpngw_bgp_apipa_0 = cidrhost(local.bgp_apipa_range3, 1)
  vhub2_vpngw_bgp_apipa_1 = cidrhost(local.bgp_apipa_range4, 1)
}

# hub1
#----------------------------

locals {
  hub1_prefix        = local.prefix == "" ? "hub1-" : join("-", [local.prefix, "hub1-"])
  hub1_location      = local.region1
  hub1_address_space = ["10.11.0.0/16"]
  hub1_domain        = "hub1"
  hub1_tags          = { env = "hub1" }
  hub1_subnets = {
    ("${local.hub1_prefix}main")    = { address_prefixes = ["10.11.0.0/24"] }
    ("${local.hub1_prefix}nva")     = { address_prefixes = ["10.11.1.0/24"] }
    ("${local.hub1_prefix}ilb")     = { address_prefixes = ["10.11.2.0/24"] }
    ("${local.hub1_prefix}dns-in")  = { address_prefixes = ["10.11.3.0/24"], delegate_dns = true }
    ("${local.hub1_prefix}dns-out") = { address_prefixes = ["10.11.4.0/24"], delegate_dns = true }
    ("GatewaySubnet")               = { address_prefixes = ["10.11.5.0/24"] }
    ("RouteServerSubnet")           = { address_prefixes = ["10.11.6.0/24"] }
    ("AzureFirewallSubnet")         = { address_prefixes = ["10.11.7.0/24"] }
  }
  hub1_default_gw_main   = cidrhost(local.hub1_subnets["${local.hub1_prefix}main"].address_prefixes[0], 1)
  hub1_default_gw_nva    = cidrhost(local.hub1_subnets["${local.hub1_prefix}nva"].address_prefixes[0], 1)
  hub1_vm_addr           = cidrhost(local.hub1_subnets["${local.hub1_prefix}main"].address_prefixes[0], 5)
  hub1_nva_addr          = cidrhost(local.hub1_subnets["${local.hub1_prefix}nva"].address_prefixes[0], 9)
  hub1_nva_ilb_addr      = cidrhost(local.hub1_subnets["${local.hub1_prefix}ilb"].address_prefixes[0], 99)
  hub1_dns_in_addr       = cidrhost(local.hub1_subnets["${local.hub1_prefix}dns-in"].address_prefixes[0], 4)
  hub1_dns_out_addr      = cidrhost(local.hub1_subnets["${local.hub1_prefix}dns-out"].address_prefixes[0], 4)
  hub1_vpngw_bgp_ip      = cidrhost(local.hub1_subnets["GatewaySubnet"].address_prefixes[0], 254)
  hub1_nva_loopback0     = "10.11.11.11"
  hub1_nva_tun_range0    = "10.11.50.0/30"
  hub1_nva_tun_range1    = "10.11.51.4/30"
  hub1_vpngw_bgp_apipa_0 = cidrhost(local.bgp_apipa_range1, 1)
  hub1_vpngw_bgp_apipa_1 = cidrhost(local.bgp_apipa_range2, 1)
  hub1_vm_dns_prefix     = "vm.${local.hub1_domain}"
  hub1_vm_dns            = "${local.hub1_vm_dns_prefix}.${local.cloud_domain}"
}

# hub2
#----------------------------

locals {
  hub2_prefix        = local.prefix == "" ? "hub2-" : join("-", [local.prefix, "hub2-"])
  hub2_location      = local.region2
  hub2_address_space = ["10.22.0.0/16"]
  hub2_domain        = "hub2"
  hub2_tags          = { env = "hub2" }
  hub2_subnets = {
    ("${local.hub2_prefix}main")    = { address_prefixes = ["10.22.0.0/24"] }
    ("${local.hub2_prefix}nva")     = { address_prefixes = ["10.22.1.0/24"] }
    ("${local.hub2_prefix}ilb")     = { address_prefixes = ["10.22.2.0/24"] }
    ("${local.hub2_prefix}dns-in")  = { address_prefixes = ["10.22.3.0/24"], delegate_dns = true }
    ("${local.hub2_prefix}dns-out") = { address_prefixes = ["10.22.4.0/24"], delegate_dns = true }
    ("GatewaySubnet")               = { address_prefixes = ["10.22.5.0/24"] }
    ("RouteServerSubnet")           = { address_prefixes = ["10.22.6.0/24"] }
    ("AzureFirewallSubnet")         = { address_prefixes = ["10.22.7.0/24"] }
  }
  hub2_default_gw_main   = cidrhost(local.hub2_subnets["${local.hub2_prefix}main"].address_prefixes[0], 1)
  hub2_default_gw_nva    = cidrhost(local.hub2_subnets["${local.hub2_prefix}nva"].address_prefixes[0], 1)
  hub2_vm_addr           = cidrhost(local.hub2_subnets["${local.hub2_prefix}main"].address_prefixes[0], 5)
  hub2_nva_addr          = cidrhost(local.hub2_subnets["${local.hub2_prefix}nva"].address_prefixes[0], 9)
  hub2_nva_ilb_addr      = cidrhost(local.hub2_subnets["${local.hub2_prefix}ilb"].address_prefixes[0], 99)
  hub2_dns_in_addr       = cidrhost(local.hub2_subnets["${local.hub2_prefix}dns-in"].address_prefixes[0], 4)
  hub2_dns_out_addr      = cidrhost(local.hub2_subnets["${local.hub2_prefix}dns-out"].address_prefixes[0], 4)
  hub2_vpngw_bgp_ip      = cidrhost(local.hub2_subnets["GatewaySubnet"].address_prefixes[0], 254)
  hub2_nva_loopback0     = "10.22.22.22"
  hub2_nva_tun_range0    = "10.22.50.0/30"
  hub2_nva_tun_range1    = "10.22.51.4/30"
  hub2_vpngw_bgp_apipa_0 = cidrhost(local.bgp_apipa_range5, 1)
  hub2_vm_dns_prefix     = "vm.${local.hub2_domain}"
  hub2_vm_dns            = "${local.hub2_vm_dns_prefix}.${local.cloud_domain}"
}

# branch1
#----------------------------

locals {
  branch1_prefix        = local.prefix == "" ? "branch1-" : join("-", [local.prefix, "branch1-"])
  branch1_location      = local.region1
  branch1_address_space = ["10.10.0.0/16"]
  branch1_nva_asn       = "65001"
  branch1_domain        = "branch1"
  branch1_tags          = { env = "branch1" }
  branch1_subnets = {
    ("${local.branch1_prefix}main") = { address_prefixes = ["10.10.0.0/24"] }
    ("${local.branch1_prefix}ext")  = { address_prefixes = ["10.10.1.0/24"] }
    ("${local.branch1_prefix}int")  = { address_prefixes = ["10.10.2.0/24"] }
    ("GatewaySubnet")               = { address_prefixes = ["10.10.3.0/24"] }
  }
  branch1_ext_default_gw = cidrhost(local.branch1_subnets["${local.branch1_prefix}ext"].address_prefixes[0], 1)
  branch1_int_default_gw = cidrhost(local.branch1_subnets["${local.branch1_prefix}int"].address_prefixes[0], 1)
  branch1_nva_ext_addr   = cidrhost(local.branch1_subnets["${local.branch1_prefix}ext"].address_prefixes[0], 9)
  branch1_nva_int_addr   = cidrhost(local.branch1_subnets["${local.branch1_prefix}int"].address_prefixes[0], 9)
  branch1_vm_addr        = cidrhost(local.branch1_subnets["${local.branch1_prefix}main"].address_prefixes[0], 5)
  branch1_dns_addr       = cidrhost(local.branch1_subnets["${local.branch1_prefix}main"].address_prefixes[0], 6)
  branch1_nva_loopback0  = "192.168.10.10"
  branch1_nva_tun_range0 = "10.10.10.0/30"
  branch1_nva_tun_range1 = "10.10.10.4/30"
  branch1_bgp_apipa_0    = cidrhost(local.bgp_apipa_range3, 2)
  branch1_bgp_apipa_1    = cidrhost(local.bgp_apipa_range4, 2)
  branch1_vm_dns_prefix  = "vm.${local.branch1_domain}"
  branch1_vm_dns         = "${local.branch1_vm_dns_prefix}.${local.onprem_domain}"
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
    ("GatewaySubnet")               = { address_prefixes = ["10.20.3.0/24"] }
  }
  branch2_ext_default_gw = cidrhost(local.branch2_subnets["${local.branch2_prefix}ext"].address_prefixes[0], 1)
  branch2_int_default_gw = cidrhost(local.branch2_subnets["${local.branch2_prefix}int"].address_prefixes[0], 1)
  branch2_nva_ext_addr   = cidrhost(local.branch2_subnets["${local.branch2_prefix}ext"].address_prefixes[0], 9)
  branch2_nva_int_addr   = cidrhost(local.branch2_subnets["${local.branch2_prefix}int"].address_prefixes[0], 9)
  branch2_vm_addr        = cidrhost(local.branch2_subnets["${local.branch2_prefix}main"].address_prefixes[0], 5)
  branch2_dns_addr       = cidrhost(local.branch2_subnets["${local.branch2_prefix}main"].address_prefixes[0], 6)
  branch2_nva_loopback0  = "192.168.20.20"
  branch2_nva_tun_range0 = "10.20.20.0/30"
  branch2_nva_tun_range1 = "10.20.20.4/30"
  branch2_vm_dns_prefix  = "vm.${local.branch2_domain}"
  branch2_vm_dns         = "${local.branch2_vm_dns_prefix}.${local.onprem_domain}"
}

# branch3
#----------------------------

locals {
  branch3_prefix        = local.prefix == "" ? "branch3-" : join("-", [local.prefix, "branch3-"])
  branch3_location      = local.region2
  branch3_address_space = ["10.30.0.0/16"]
  branch3_nva_asn       = "65003"
  branch3_domain        = "branch3"
  branch3_tags          = { env = "branch3" }
  branch3_subnets = {
    ("${local.branch3_prefix}main") = { address_prefixes = ["10.30.0.0/24"] }
    ("${local.branch3_prefix}ext")  = { address_prefixes = ["10.30.1.0/24"] }
    ("${local.branch3_prefix}int")  = { address_prefixes = ["10.30.2.0/24"] }
  }
  branch3_ext_default_gw = cidrhost(local.branch3_subnets["${local.branch3_prefix}ext"].address_prefixes[0], 1)
  branch3_int_default_gw = cidrhost(local.branch3_subnets["${local.branch3_prefix}int"].address_prefixes[0], 1)
  branch3_nva_ext_addr   = cidrhost(local.branch3_subnets["${local.branch3_prefix}ext"].address_prefixes[0], 9)
  branch3_nva_int_addr   = cidrhost(local.branch3_subnets["${local.branch3_prefix}int"].address_prefixes[0], 9)
  branch3_vm_addr        = cidrhost(local.branch3_subnets["${local.branch3_prefix}main"].address_prefixes[0], 5)
  branch3_dns_addr       = cidrhost(local.branch3_subnets["${local.branch3_prefix}main"].address_prefixes[0], 6)
  branch3_nva_loopback0  = "192.168.30.30"
  branch3_nva_tun_range0 = "10.30.30.0/30"
  branch3_nva_tun_range1 = "10.30.30.4/30"
  branch3_bgp_apipa_0    = cidrhost(local.bgp_apipa_range7, 2)
  branch3_bgp_apipa_1    = cidrhost(local.bgp_apipa_range8, 2)
  branch3_vm_dns_prefix  = "vm.${local.branch3_domain}"
  branch3_vm_dns         = "${local.branch3_vm_dns_prefix}.${local.onprem_domain}"
}

# branch4
#----------------------------

locals {
  branch4_prefix        = local.prefix == "" ? "branch4-" : join("-", [local.prefix, "branch4-"])
  branch4_location      = local.region2
  branch4_address_space = ["10.40.0.0/16"]
  branch4_nva_asn       = "65004"
  branch4_domain        = "branch4"
  branch4_tags          = { env = "branch4" }
  branch4_subnets = {
    ("${local.branch4_prefix}main") = { address_prefixes = ["10.40.0.0/24"] }
    ("${local.branch4_prefix}ext")  = { address_prefixes = ["10.40.1.0/24"] }
    ("${local.branch4_prefix}int")  = { address_prefixes = ["10.40.2.0/24"] }
    ("GatewaySubnet")               = { address_prefixes = ["10.40.3.0/24"] }
  }
  branch4_ext_default_gw = cidrhost(local.branch4_subnets["${local.branch4_prefix}ext"].address_prefixes[0], 1)
  branch4_int_default_gw = cidrhost(local.branch4_subnets["${local.branch4_prefix}int"].address_prefixes[0], 1)
  branch4_nva_ext_addr   = cidrhost(local.branch4_subnets["${local.branch4_prefix}ext"].address_prefixes[0], 9)
  branch4_nva_int_addr   = cidrhost(local.branch4_subnets["${local.branch4_prefix}int"].address_prefixes[0], 9)
  branch4_vm_addr        = cidrhost(local.branch4_subnets["${local.branch4_prefix}main"].address_prefixes[0], 5)
  branch4_dns_addr       = cidrhost(local.branch4_subnets["${local.branch4_prefix}main"].address_prefixes[0], 6)
  branch4_nva_loopback0  = "192.168.40.40"
  branch4_nva_tun_range0 = "10.40.40.0/30"
  branch4_nva_tun_range1 = "10.40.40.4/30"
  branch4_vm_dns_prefix  = "vm.${local.branch4_domain}"
  branch4_vm_dns         = "${local.branch4_vm_dns_prefix}.${local.onprem_domain}"
}

# spoke1
#----------------------------

locals {
  spoke1_prefix        = local.prefix == "" ? "spoke1-" : join("-", [local.prefix, "spoke1-"])
  spoke1_location      = local.region1
  spoke1_address_space = ["10.1.0.0/16"]
  spoke1_domain        = "spoke1"
  spoke1_tags          = { env = "spoke1" }
  spoke1_subnets = {
    ("${local.spoke1_prefix}main")  = { address_prefixes = ["10.1.0.0/24"] }
    ("${local.spoke1_prefix}appgw") = { address_prefixes = ["10.1.1.0/24"] }
  }
  spoke1_vm_addr       = cidrhost(local.spoke1_subnets["${local.spoke1_prefix}main"].address_prefixes[0], 5)
  spoke1_appgw_addr    = cidrhost(local.spoke1_subnets["${local.spoke1_prefix}appgw"].address_prefixes[0], 99)
  spoke1_vm_dns_prefix = "vm.${local.spoke1_domain}"
  spoke1_vm_dns        = "${local.spoke1_vm_dns_prefix}.${local.cloud_domain}"
}

# spoke2
#----------------------------

locals {
  spoke2_prefix        = local.prefix == "" ? "spoke2-" : join("-", [local.prefix, "spoke2-"])
  spoke2_location      = local.region1
  spoke2_address_space = ["10.2.0.0/16"]
  spoke2_domain        = "spoke2"
  spoke2_tags          = { env = "spoke2" }
  spoke2_subnets = {
    ("${local.spoke2_prefix}main")  = { address_prefixes = ["10.2.0.0/24"] }
    ("${local.spoke2_prefix}appgw") = { address_prefixes = ["10.2.1.0/24"] }
  }
  spoke2_vm_addr       = cidrhost(local.spoke2_subnets["${local.spoke2_prefix}main"].address_prefixes[0], 5)
  spoke2_appgw_addr    = cidrhost(local.spoke2_subnets["${local.spoke2_prefix}appgw"].address_prefixes[0], 99)
  spoke2_vm_dns_prefix = "vm.${local.spoke2_domain}"
  spoke2_vm_dns        = "${local.spoke2_vm_dns_prefix}.${local.cloud_domain}"
}

# spoke3
#----------------------------

locals {
  spoke3_prefix        = local.prefix == "" ? "spoke3-" : join("-", [local.prefix, "spoke3-"])
  spoke3_location      = local.region1
  spoke3_address_space = ["10.3.0.0/16"]
  spoke3_domain        = "spoke3"
  spoke3_tags          = { env = "spoke3" }
  spoke3_subnets = {
    ("${local.spoke3_prefix}main")  = { address_prefixes = ["10.3.0.0/24"] }
    ("${local.spoke3_prefix}appgw") = { address_prefixes = ["10.3.1.0/24"] }
    ("RouteServerSubnet")           = { address_prefixes = ["10.3.2.0/24"] }
  }
  spoke3_vm_addr       = cidrhost(local.spoke3_subnets["${local.spoke3_prefix}main"].address_prefixes[0], 5)
  spoke3_appgw_addr    = cidrhost(local.spoke3_subnets["${local.spoke3_prefix}appgw"].address_prefixes[0], 99)
  spoke3_vm_dns_prefix = "vm.${local.spoke3_domain}"
  spoke3_vm_dns        = "${local.spoke3_vm_dns_prefix}.${local.cloud_domain}"
}

# spoke4
#----------------------------

locals {
  spoke4_prefix        = local.prefix == "" ? "spoke4-" : join("-", [local.prefix, "spoke4-"])
  spoke4_location      = local.region2
  spoke4_address_space = ["10.4.0.0/16"]
  spoke4_domain        = "spoke4"
  spoke4_tags          = { env = "spoke4" }
  spoke4_subnets = {
    ("${local.spoke4_prefix}main")  = { address_prefixes = ["10.4.0.0/24"] }
    ("${local.spoke4_prefix}appgw") = { address_prefixes = ["10.4.1.0/24"] }
  }
  spoke4_vm_addr       = cidrhost(local.spoke4_subnets["${local.spoke4_prefix}main"].address_prefixes[0], 5)
  spoke4_appgw_addr    = cidrhost(local.spoke4_subnets["${local.spoke4_prefix}appgw"].address_prefixes[0], 99)
  spoke4_vm_dns_prefix = "vm.${local.spoke4_domain}"
  spoke4_vm_dns        = "${local.spoke4_vm_dns_prefix}.${local.cloud_domain}"
}

# spoke5
#----------------------------

locals {
  spoke5_prefix        = local.prefix == "" ? "spoke5-" : join("-", [local.prefix, "spoke5-"])
  spoke5_location      = local.region2
  spoke5_address_space = ["10.5.0.0/16"]
  spoke5_domain        = "spoke5"
  spoke5_tags          = { env = "spoke5" }
  spoke5_subnets = {
    ("${local.spoke5_prefix}main")  = { address_prefixes = ["10.5.0.0/24"] }
    ("${local.spoke5_prefix}appgw") = { address_prefixes = ["10.5.1.0/24"] }
  }
  spoke5_vm_addr       = cidrhost(local.spoke5_subnets["${local.spoke5_prefix}main"].address_prefixes[0], 5)
  spoke5_appgw_addr    = cidrhost(local.spoke5_subnets["${local.spoke5_prefix}appgw"].address_prefixes[0], 99)
  spoke5_vm_dns_prefix = "vm.${local.spoke5_domain}"
  spoke5_vm_dns        = "${local.spoke5_vm_dns_prefix}.${local.cloud_domain}"
}

# spoke6
#----------------------------

locals {
  spoke6_prefix        = local.prefix == "" ? "spoke6-" : join("-", [local.prefix, "spoke6-"])
  spoke6_location      = local.region2
  spoke6_address_space = ["10.6.0.0/16"]
  spoke6_domain        = "spoke6"
  spoke6_tags          = { env = "spoke6" }
  spoke6_subnets = {
    ("${local.spoke6_prefix}main")  = { address_prefixes = ["10.6.0.0/24"] }
    ("${local.spoke6_prefix}appgw") = { address_prefixes = ["10.6.1.0/24"] }
    ("RouteServerSubnet")           = { address_prefixes = ["10.6.2.0/24"] }
  }
  spoke6_vm_addr       = cidrhost(local.spoke6_subnets["${local.spoke6_prefix}main"].address_prefixes[0], 5)
  spoke6_appgw_addr    = cidrhost(local.spoke6_subnets["${local.spoke6_prefix}appgw"].address_prefixes[0], 99)
  spoke6_vm_dns_prefix = "vm.${local.spoke6_domain}"
  spoke6_vm_dns        = "${local.spoke6_vm_dns_prefix}.${local.cloud_domain}"
}

# megaport
#----------------------------
locals {
  megaport_prefix       = "salawu"
  megaport_asn          = 65111
  megaport_hub1_vlan    = "110"
  megaport_branch2_vlan = "100"
}
