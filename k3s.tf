# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  subscription_id = "a779aaef-4693-4c3a-bf68-6aa99ffe1acf"
  features {}
}

resource "azurerm_resource_group" "k3s" {
  name     = "k3s"
  location = "East US 2"
}

resource "azurerm_virtual_network" "k3s-vnet" {
 name                = "k3s-vnet"
 address_space       = ["10.0.0.0/16"]
 location            = "East US 2"
 resource_group_name = azurerm_resource_group.k3s.name
}

resource "azurerm_subnet" "k3s-subnet" {
 name                 = "k3s-subnet"
 resource_group_name  = azurerm_resource_group.k3s.name
 virtual_network_name = azurerm_virtual_network.k3s-vnet.name
 address_prefixes       = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "k3s-ip" {
 name                         = "k3s-ip"
 location                     = "East US 2"
 resource_group_name          = azurerm_resource_group.k3s.name
 allocation_method            = "Static"
 domain_name_label            = "k3s"
}

resource "azurerm_network_security_group" "k3s-nsg" {
    name                = "k3s-nsg"
    location            = "eastus2"
    resource_group_name = azurerm_resource_group.k3s.name

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
        name                       = "HTTPS"
        priority                   = 1003
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_network_interface" "k3s-nic" {
    name                        = "k3s-nic"
    location                    = "eastus2"
    resource_group_name         = azurerm_resource_group.k3s.name

    ip_configuration {
        name                          = "k3s-nic-config"
        subnet_id                     = azurerm_subnet.k3s-subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.k3s-ip.id
    }
}

resource "azurerm_network_interface_security_group_association" "k3s-nic-nsg-association" {
    network_interface_id      = azurerm_network_interface.k3s-nic.id
    network_security_group_id = azurerm_network_security_group.k3s-nsg.id
}

resource "azurerm_linux_virtual_machine" "k3s" {
    name                  = "k3s"
    location              = "eastus2"
    resource_group_name   = azurerm_resource_group.k3s.name
    network_interface_ids = [azurerm_network_interface.k3s-nic.id]
    size                  = "Standard_B1s"

    os_disk {
        name                 = "k3s-osdisk"
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Debian"
        offer     = "debian-10"
        sku       = "10"
        version   = "latest"
    }

    admin_username = "chef"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "chef"
        public_key = file("~/.ssh/id_rsa.pub")
    }
}
