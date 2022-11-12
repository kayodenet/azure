
# public ip

resource "azurerm_public_ip" "this" {
  count               = var.enable_public_ip == true ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.name}pip"
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = var.tags
}

# interface

resource "azurerm_network_interface" "this" {
  resource_group_name  = var.resource_group
  name                 = "${local.name}nic"
  location             = var.location
  tags                 = var.tags
  enable_ip_forwarding = var.enable_ip_forwarding
  ip_configuration {
    name                          = "${local.name}nic"
    subnet_id                     = var.subnet
    private_ip_address_allocation = var.private_ip == null ? "Dynamic" : "Static"
    private_ip_address            = var.private_ip == null ? null : var.private_ip
    public_ip_address_id          = var.enable_public_ip ? azurerm_public_ip.this.0.id : null
  }
}

# vm

resource "azurerm_linux_virtual_machine" "this" {
  resource_group_name = var.resource_group
  name                = var.name
  location            = var.location
  zone                = var.zone
  size                = var.vm_size
  tags                = var.tags
  custom_data         = var.custom_data
  network_interface_ids = [
    azurerm_network_interface.this.id
  ]
  os_disk {
    name                 = "${local.name}vm-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  computer_name  = "${local.name}vm"
  admin_username = var.admin_username
  admin_password = var.admin_password
  boot_diagnostics {
    storage_account_uri = var.storage_account.primary_blob_endpoint
  }
  disable_password_authentication = false
}
