resource "azurerm_resource_group" "infra_rg" {
  name     = "${var.prefix}-${var.env}"
  location = var.region
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.infra_rg.location
  resource_group_name = azurerm_resource_group.infra_rg.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.infra_rg.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.infra_rg.location
  resource_group_name = azurerm_resource_group.infra_rg.name
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.infra_rg.location
  resource_group_name = azurerm_resource_group.infra_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  #
  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP8080"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.infra_rg.location
  resource_group_name = azurerm_resource_group.infra_rg.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm-${var.env}"
  location              = azurerm_resource_group.infra_rg.location
  resource_group_name   = azurerm_resource_group.infra_rg.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  # delete the OS disk, data disk automatically when deleting the VM
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = data.azurerm_key_vault_secret.username.value
    admin_password = data.azurerm_key_vault_secret.password.value
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "${var.env}"
  }

  connection {
    type     = "ssh"
    user     = data.azurerm_key_vault_secret.username.value
    password = data.azurerm_key_vault_secret.password.value
    host     = azurerm_public_ip.my_terraform_public_ip.ip_address
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y default-jdk",
    ]
  }

  provisioner "file" {
    source      = "./install-tomcat-script.sh"
    destination = "/tmp/install-tomcat-script.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install-tomcat-script.sh",
      "sed -i 's/\r$//' /tmp/install-tomcat-script.sh",
      "sudo bash /tmp/install-tomcat-script.sh",
      "sudo chmod 777 /opt/tomcat/webapps",
    ]
  }
}
