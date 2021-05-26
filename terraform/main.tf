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

resource "azurerm_resource_group" "kube" {
  name     = "kube"
  location = "eastus"
}

resource "azurerm_virtual_network" "kube-galenguyer-vnet" {
 name                = "kube-galenguyer-vnet"
 address_space       = ["10.0.0.0/16"]
 location            = "eastus"
 resource_group_name = azurerm_resource_group.kube.name
}

resource "azurerm_subnet" "kube-galenguyer-subnet" {
 name                 = "kube-galenguyer-subnet"
 resource_group_name  = azurerm_resource_group.kube.name
 virtual_network_name = azurerm_virtual_network.kube-galenguyer-vnet.name
 address_prefixes       = ["10.0.8.0/24"]
}

resource "azurerm_network_security_group" "kube-galenguyer-nsg" {
    name                = "kube-galenguyer-nsg"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.kube.name

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
}
