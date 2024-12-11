# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2. VM & Networking Resources
# Creates 2 VMs, 1 Windows and 1 Linux, with different NSG exposures
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resource "azurerm_virtual_network" "lab_vnet" {
  for_each            = local.vm_config
  name                = "${local.resource_prefix}-vnet-${each.value.suffix}"
  address_space       = ["10.0.0.0/24"]
  location            = azurerm_resource_group.lab_environment.location
  resource_group_name = azurerm_resource_group.lab_environment.name
}

resource "azurerm_subnet" "lab_subnet" {
  for_each             = local.vm_config
  name                 = "${local.resource_prefix}-subnet-${each.value.suffix}"
  resource_group_name  = azurerm_resource_group.lab_environment.name
  virtual_network_name = azurerm_virtual_network.lab_vnet[each.key].name
  address_prefixes     = ["10.0.0.32/27"]
}

resource "azurerm_public_ip" "lab_pip" {
  for_each            = local.vm_config
  name                = "${local.resource_prefix}-pip-${each.value.suffix}"
  location            = azurerm_resource_group.lab_environment.location
  resource_group_name = azurerm_resource_group.lab_environment.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "lab_nic" {
  for_each            = local.vm_config
  name                = "${local.resource_prefix}-nic-${each.value.suffix}"
  location            = azurerm_resource_group.lab_environment.location
  resource_group_name = azurerm_resource_group.lab_environment.name

  ip_configuration {
    name                          = "${local.resource_prefix}-ip-${each.value.suffix}"
    subnet_id                     = azurerm_subnet.lab_subnet[each.key].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab_pip[each.key].id
  }
}

resource "azurerm_network_security_group" "lab_nsg" {
  for_each            = local.vm_config
  name                = "${local.resource_prefix}-nsg-${each.value.suffix}"
  location            = azurerm_resource_group.lab_environment.location
  resource_group_name = azurerm_resource_group.lab_environment.name

  security_rule {
    name                       = "Allow-${each.value.allowed_port}"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = each.value.allowed_port
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "lab_nsg_nic_association" {
  for_each                  = local.vm_config
  network_interface_id      = azurerm_network_interface.lab_nic[each.key].id
  network_security_group_id = azurerm_network_security_group.lab_nsg[each.key].id
}

resource "azurerm_windows_virtual_machine" "lab_vm" {
  # 15 character limit, ommit the prefix
  name                = "vm-${local.vm_config.vm1.suffix}"
  resource_group_name = azurerm_resource_group.lab_environment.name
  location            = azurerm_resource_group.lab_environment.location
  size                = "Standard_F2"
  admin_username      = "local_admin_user"
  admin_password      = random_password.password.result

  network_interface_ids = [
    azurerm_network_interface.lab_nic["vm1"].id,
  ]

  os_disk {
    name                 = "${local.resource_prefix}-osdisk-${local.vm_config.vm1.suffix}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = local.vm_config.vm1.image_publisher
    offer     = local.vm_config.vm1.image_offer
    sku       = local.vm_config.vm1.image_sku
    version   = local.vm_config.vm1.image_version
  }
}

resource "azurerm_linux_virtual_machine" "lab_vm" {
  name                            = "${local.resource_prefix}-vm-${local.vm_config.vm2.suffix}"
  resource_group_name             = azurerm_resource_group.lab_environment.name
  location                        = azurerm_resource_group.lab_environment.location
  size                            = "Standard_F2"
  admin_username                  = "local_admin_user"
  admin_password                  = random_password.password.result
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.lab_nic["vm2"].id,
  ]

  os_disk {
    name                 = "${local.resource_prefix}-osdisk-${local.vm_config.vm2.suffix}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = local.vm_config.vm2.image_publisher
    offer     = local.vm_config.vm2.image_offer
    sku       = local.vm_config.vm2.image_sku
    version   = local.vm_config.vm2.image_version
  }
}