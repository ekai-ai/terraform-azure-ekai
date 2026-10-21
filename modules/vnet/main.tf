resource "azurerm_virtual_network" "vnet" {
  name                = "${var.cluster_name}-vnet"
  location            = var.region
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_cidr]

  tags = var.tags
}
resource "azurerm_subnet" "public_subnet_1" {
  name                 = "${var.cluster_name}-pub-sub-1a"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.pub_sub_1_a_cidr]

  service_endpoints = ["Microsoft.AzureActiveDirectory"]

}
resource "azurerm_route_table" "public_route_table" {
  name                = "${var.cluster_name}-route-table"
  location            = var.region
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_route" "public_route" {
  name                = "default-route"
  resource_group_name = var.resource_group_name
  route_table_name    = azurerm_route_table.public_route_table.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "Internet"

}
resource "azurerm_subnet_route_table_association" "public_subnet_route_table_association" {
  subnet_id      = azurerm_subnet.public_subnet_1.id
  route_table_id = azurerm_route_table.public_route_table.id

}

#private subnet
resource "azurerm_subnet" "private_subnet_1" {
  name                 = "${var.cluster_name}-pri-sub-1"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.pri_sub_1_cidr]

}

resource "azurerm_subnet" "private_subnet_2" {
  name                 = "${var.cluster_name}-pri-sub-2"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.pri_sub_2_cidr]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }

}

resource "azurerm_subnet" "private_subnet_3" {
  name                 = "${var.cluster_name}-pri-sub-3"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.pri_sub_3_cidr]
}
resource "azurerm_route_table" "private_route_table" {
  name                = "${var.cluster_name}-private-route-table"
  location            = var.region
  resource_group_name = var.resource_group_name


  tags = var.tags
}

resource "azurerm_subnet_route_table_association" "private_subnet_route_table_association_1" {
  subnet_id      = azurerm_subnet.private_subnet_1.id
  route_table_id = azurerm_route_table.private_route_table.id
}

resource "azurerm_subnet_route_table_association" "private_subnet_route_table_association_2" {
  subnet_id      = azurerm_subnet.private_subnet_2.id
  route_table_id = azurerm_route_table.private_route_table.id
}

resource "azurerm_subnet_route_table_association" "private_subnet_route_table_association_3" {
  subnet_id      = azurerm_subnet.private_subnet_3.id
  route_table_id = azurerm_route_table.private_route_table.id

}
