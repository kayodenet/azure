
variable "resource_group" {
  description = "resource group name"
  type        = any
}

variable "name" {
  description = "prefix to append before all resources"
  type        = string
}

variable "location" {
  description = "vnet region location"
  type        = string
}

variable "tags" {
  description = "tags for all hub resources"
  type        = map(any)
  default     = null
}

variable "storage_account" {
  description = "storage account object"
  type        = any
  default     = null
}

variable "admin_username" {
  description = "private dns zone name"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "private dns zone name"
  type        = string
  default     = "Password123"
}

variable "ssh_public_key" {
  description = "sh public key data"
  type        = string
  default     = null
}

/*variable "network_security_group_id_main" {
  description = "network security group id for main subnet"
  type        = string
  default     = null
}

variable "network_security_group_id_ext" {
  description = "network security group id for external subnet"
  type        = string
  default     = null
}

variable "network_security_group_id_int" {
  description = "network security group id for internal subnet"
  type        = string
  default     = null
}

variable "network_security_group_id_appgw" {
  description = "network security group id for appgw subnet"
  type        = string
  default     = null
}*/

variable "private_dns_zone" {
  description = "private dns zone"
  type        = string
  default     = null
}

variable "dns_zone_linked_vnets" {
  description = "private dns zone"
  type        = list(string)
  default     = []
}

variable "dns_zone_linked_rulesets" {
  description = "private dns rulesets"
  type        = list(string)
  default     = []
}

variable "vnet_config" {
  type = list(object({
    address_space               = list(string)
    subnets                     = map(any)
    subnets_nat_gateway         = optional(list(string), [])
    nsg_id                      = optional(string)
    dns_servers                 = optional(list(string))
    enable_private_dns_resolver = optional(bool, false)
  }))
  default = []
}

variable "vm_config" {
  type = list(object({
    dns_host             = optional(string)
    zone                 = optional(string, null)
    size                 = optional(string, "Standard_B1s")
    private_ip           = optional(string, null)
    public_ip            = optional(string, null)
    custom_data          = optional(string, null)
    enable_ip_forwarding = optional(bool, false)
    use_vm_extension     = optional(bool, false)
  }))
  default = []
}

variable "dns_config" {
  type = list(object({
    dns_host             = optional(string)
    zone                 = optional(string, null)
    size                 = optional(string, "Standard_B1s")
    private_ip           = optional(string, null)
    public_ip            = optional(string, null)
    custom_data          = optional(string, null)
    enable_ip_forwarding = optional(bool, false)
    use_vm_extension     = optional(bool, false)
  }))
  default = []
}
