resource "azurerm_public_ip" "kube-galenguyer-03-ip" {
 name                         = "kube-galenguyer-03-ip"
 location                     = "East US"
 resource_group_name          = azurerm_resource_group.kube.name
 allocation_method            = "Static"
 domain_name_label            = "kube-galenguyer-03"
}

resource "azurerm_network_interface" "kube-galenguyer-03-nic" {
    name                        = "kube-galenguyer-03-nic"
    location                    = "eastus"
    resource_group_name         = azurerm_resource_group.kube.name

    ip_configuration {
        name                          = "kube-galenguyer-03-nic-config"
        subnet_id                     = azurerm_subnet.kube-galenguyer-subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.kube-galenguyer-03-ip.id
    }
}

resource "azurerm_network_interface_security_group_association" "kube-galenguyer-03-nic-nsg-association" {
    network_interface_id      = azurerm_network_interface.kube-galenguyer-03-nic.id
    network_security_group_id = azurerm_network_security_group.kube-galenguyer-nsg.id
}

resource "azurerm_linux_virtual_machine" "kube-galenguyer-03" {
    name                  = "kube-galenguyer-03"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.kube.name
    network_interface_ids = [azurerm_network_interface.kube-galenguyer-03-nic.id]
    size                  = "Standard_B1s"

    os_disk {
        name                 = "kube-galenguyer-03-osdisk"
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