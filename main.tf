terraform{
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "4.5.0"
        }
    }

}

resource "azurerm_resource_group" "app-grp" {
    name     = "app-grp"
    location = local.resource_location

}

resource "azurerm_virtual_network" "app-network" {
  name                = local.virtual_network.name
  location            = local.resource_location
  resource_group_name = azurerm_resource_group.app-grp.name
  address_space       = local.virtual_network.address_prefixes

}

resource "azurerm_subnet" "websubnet01" {
  name                 = local.subnets[0].name
  resource_group_name  = azurerm_resource_group.app-grp.name
  virtual_network_name = azurerm_virtual_network.app-network.name
  address_prefixes     = local.subnets[0].address_prefixname

  }

resource "azurerm_subnet" "appsubnet01" {
  name                 = local.subnets[1].name
  resource_group_name  = azurerm_resource_group.app-grp.name
  virtual_network_name = azurerm_virtual_network.app-network.name
  address_prefixes     = local.subnets[1].address_prefixname

  }

  resource "azurerm_network_interface" "webinterface01" {
  name                = "webinterface01"
  location            = local.resource_location
  resource_group_name = azurerm_resource_group.app-grp.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.websubnet01.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.webip01.id
  }
}

resource "azurerm_public_ip" "webip01" {
  name                = "webip01"
  resource_group_name = azurerm_resource_group.app-grp.name
  location            = local.resource_location
  allocation_method   = "Static"

}

resource "azurerm_network_security_group" "app-nsg" {
  name                = "app-nsg"
  location            = local.resource_location
  resource_group_name = azurerm_resource_group.app-grp.name
  security_rule {
    name                       = "AllowRDP"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_subnet_network_security_group_association" "websubnet01_appnsg" {
  subnet_id                 = azurerm_subnet.websubnet01.id
  network_security_group_id = azurerm_network_security_group.app-nsg.id
}

resource "azurerm_subnet_network_security_group_association" "appsubnet01_appnsg" {
  subnet_id                 = azurerm_subnet.appsubnet01.id
  network_security_group_id = azurerm_network_security_group.app-nsg.id
}