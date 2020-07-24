provider "azurerm" {
    version = "2.5.0"  
    features {}
}

terraform {
    backend "azurerm" {
        resource_group_name  = "aoha"
        storage_account_name = "storagetes001"
        container_name       = "aohaterraform"
        key                  = "terraform.tfstate"
    }
}

resource "azurerm_resource_group" "Terratest" {
  name     = "Terraform-demo"
  location = var.region
}

resource "azurerm_virtual_network" "Terratest" {
  name                = "DemoTerravnet"
  address_space       = var.network_address_space
  location            = azurerm_resource_group.Terratest.location
  resource_group_name = azurerm_resource_group.Terratest.name
}

resource "azurerm_subnet" "Terratest" {
  name                 = "DemoTerrasubnet"
  resource_group_name  = azurerm_resource_group.Terratest.name
  virtual_network_name = azurerm_virtual_network.Terratest.name
  address_prefix       = var.subnet_address_space
}

resource "azurerm_network_interface" "Terratest" {
  count               = var.instance_count
  name                = "DemoTerranic-${count.index + 1}"
  #name                = "DemoTerranic"
  location            = azurerm_resource_group.Terratest.location
  resource_group_name = azurerm_resource_group.Terratest.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.Terratest.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "Terratest" {
    name                = "DemoTerraNSG"
    location            = azurerm_resource_group.Terratest.location
    resource_group_name = azurerm_resource_group.Terratest.name
    
    security_rule {
        name                       = "RDP"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Terraform Demo"
        owner       = "Pratik"
        Build-ID          = var.buildid
    }
}

resource "azurerm_network_interface_security_group_association" "Terratest" {
  count               = var.instance_count
  network_interface_id      = azurerm_network_interface.Terratest[count.index].id
  network_security_group_id = azurerm_network_security_group.Terratest.id
}

resource "azurerm_windows_virtual_machine" "Terratest" {
  count               = var.instance_count
  name                = "DemoTerraVM-${count.index + 1}"
  resource_group_name = azurerm_resource_group.Terratest.name
  location            = azurerm_resource_group.Terratest.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  tags = {
    Name = "Pratik test"
    environment = "Terraform Demo"
    Build-ID          = var.buildid
  }
  network_interface_ids = [
    azurerm_network_interface.Terratest[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

# Section For Variable
variable "region" {  
  default = "East US"
  description = "Name of the region to create resource"
}

variable "network_address_space" {
  default = ["10.0.0.0/16"]
}

variable "buildid" {
 type     = string
 description = "Azure build ID"
}

variable "subnet_address_space" {
    default = "10.0.0.0/24"
}

variable "instance_count" {
  default = 2
}
