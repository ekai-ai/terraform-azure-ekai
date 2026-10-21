output "public_subnet_ids" {
  value = [azurerm_subnet.public_subnet_1.id]
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}
output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value = [
    azurerm_subnet.private_subnet_1.id,
    azurerm_subnet.private_subnet_2.id,
    azurerm_subnet.private_subnet_3.id
  ]
}
