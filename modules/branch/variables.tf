
variable "resource_group_name" {
  description = "resource group name"
}

variable "location" {
  description = "location"
}

variable "prefix" {
  description = "prefix for all resources"
}

variable "address_space" {
  description = "vnet address space"
}

variable "subnets" {
  description = "subnets"
}

variable "network_security_group_id" {
  description = "subnnetwork security group id"
}

variable "private_ip" {
  description = "private ip of vm"
}

variable "storage_account" {
  description = "storage account for diagnostics"
}

variable "admin_username" {
  description = "admin username"
  default     = "azureuser"
}

variable "admin_password" {
  description = "admin password"
  default     = "Password123"
}

variable "custom_data" {
  description = "cloud init custom data"
  default     = ""
}
