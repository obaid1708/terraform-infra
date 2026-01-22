terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}
provider "azurerm" {
  features {}
  client_id       = "bc7ef0fc-b0e7-4ec2-8536-4e6e782695c0"
  client_secret   = "qxX8Q~.SCsrNwfrBEsd17xLHGxNvNF~ql6otiavl"
  subscription_id = "1467e2e0-fbcd-4ddb-9152-e6ec5035af83"
  tenant_id       = "69c24dfe-cbc6-4aef-9110-d1a281df1c73"
}
# hello


resource "azurerm_resource_group" "obaid-rg" {
  name     = "obaid-rg-us"
  location = "australiaeast"
  lifecycle {
    create_before_destroy = true
  }
}
resource "azurerm_virtual_network" "obaid-vnet-tf" {
  name                = "obaid-vnet-tf"
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.obaid-rg.name
  location            = "australiaeast"
}
resource "azurerm_subnet" "obaid-subnet-tf" {
  name                 = "obaid-subnet-tf"
  resource_group_name  = azurerm_resource_group.obaid-rg.name
  virtual_network_name = azurerm_virtual_network.obaid-vnet-tf.name
  address_prefixes     = ["10.0.0.0/23"]
}
resource "azurerm_network_security_group" "nsg-tf" {
  name     = "nsg-tf"
  location = "australiaeast"

  resource_group_name = azurerm_resource_group.obaid-rg.name
  security_rule {
    name                       = "ssh"
    destination_port_range     = "22"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_address_prefix = "*"
    source_port_range          = "*"
    source_address_prefix      = "*"
    priority                   = 100
    direction                  = "Inbound"
  }
}
resource "azurerm_public_ip" "obaid-tfpip" {
  name                = "obaid-tf"
  location            = "australiaeast"
  resource_group_name = azurerm_resource_group.obaid-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

}
resource "azurerm_network_interface" "obaid-nic-tf" {
  name                = "obaid-nic-tf"
  location            = "australiaeast"
  resource_group_name = azurerm_resource_group.obaid-rg.name

  ip_configuration {
    name                          = "pip"
    subnet_id                     = azurerm_subnet.obaid-subnet-tf.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.obaid-tfpip.id
  }
  # lifecycle {
  #   ignore_changes = "true" 
  # }
}
resource "azurerm_linux_virtual_machine" "obaid-vm-tf" {
  name                  = "obaid-vm-tf-git"
  resource_group_name   = azurerm_resource_group.obaid-rg.name
  location              = "australiaeast"
  size                  = "Standard_D2ls_v5"
  admin_username        = "obaid"
  network_interface_ids = [azurerm_network_interface.obaid-nic-tf.id]
  admin_password        = "Obaid@123"
  # admin_ssh_key {
  #    username = "obaid"
  #    public_key = file("/var/lib/jenkins/.ssh/id_rsa")
  # }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  computer_name                   = "obaid-vm-tf"
  disable_password_authentication = false
}
output "public_ip_address" {
  value = azurerm_public_ip.obaid-tfpip.ip_address
}


resource "azurerm_network_interface_security_group_association" "nsg_nic_assoc" {
  network_interface_id      = azurerm_network_interface.obaid-nic-tf.id
  network_security_group_id = azurerm_network_security_group.nsg-tf.id
}

