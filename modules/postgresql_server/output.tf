
output "postgresql_server_fqdn_ekai" {
  description = "Fully qualified domain name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.ekai-db.fqdn
}

output "postgresql_server_admin_login_ekai" {
  description = "Administrator login name for the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.ekai-db.administrator_login
}

output "postgresql_server_admin_password_ekai" {
  description = "Administrator login password for the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.ekai-db.administrator_password
  sensitive   = true
}
output "ekai_dbname" {
  description = "Ekai DB name"
  value       = azurerm_postgresql_flexible_server_database.ekai-database.name
}