

resource "azurerm_private_dns_zone" "ekai-db" {
  name                = "ekai-${var.env_name}.postgres.database.azure.com"
  resource_group_name = var.resource_group_name

  tags = var.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "ekai" {
  name                  = "ekaiVnetZone.com"
  private_dns_zone_name = azurerm_private_dns_zone.ekai-db.name
  virtual_network_id    = var.vnet_id
  resource_group_name   = var.resource_group_name
  tags                  = var.tags

}
resource "azurerm_postgresql_flexible_server" "ekai-db" {
  # env_name folded in -- without it, two self-service envs in the same
  # region collide on the same server name (confirmed: the original
  # "ekai-saas-db-<region>" name has no per-env component at all).
  name     = "ekai-${var.env_name}-db-${var.region}"
  location = var.region

  resource_group_name = var.resource_group_name
  delegated_subnet_id = var.subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.ekai-db.id
  sku_name            = var.postgres_flexible_server_sku_name
  zone                = var.enable_ha ? "1" : null
  dynamic "high_availability" {
    for_each = var.enable_ha ? [1] : []
    content {
      mode                      = "SameZone"
      standby_availability_zone = "2"
    }
  }
  storage_mb             = var.postgres_flexible_server_storage_mb
  backup_retention_days  = 7
  auto_grow_enabled      = true
  administrator_login    = var.backend_db_username
  administrator_password = var.backend_db_password
  version                = var.postgresql_version

  public_network_access_enabled = false

  tags = var.tags

  # Azure auto-assigns a zone when one isn't specified, and refuses to change
  # zone independently of `high_availability.standby_availability_zone`. Once
  # the server is created, we let Azure keep whatever zone it picked — this
  # avoids "zone can only be changed when exchanged with..." errors when HA
  # toggles or when re-applying after a partial failure.
  lifecycle {
    ignore_changes = [zone]
  }
}
resource "azurerm_postgresql_flexible_server_database" "ekai-database" {
  name      = var.backend_db_name
  server_id = azurerm_postgresql_flexible_server.ekai-db.id
  collation = "en_US.utf8"
  charset   = "utf8"

}
# pgvector allowlist + the semantics database that was its only consumer
# (created by the now-removed modules/postgresql_db_init Job) were removed
# together -- the semantics service has been removed from the product
# entirely, matching the same outright removal already done in
# devops/aws-terraform, devops/gcp-terraform, and terraform-google-ekai.

#resource "azurerm_postgresql_flexible_server" "ekai-db-replica" {
#  name                          = "ekai-db-replica"
#  resource_group_name           = var.resource_group_name
#  location                      = var.region
#  create_mode                   = "Replica"
#  source_server_id              = azurerm_postgresql_flexible_server.ekai-db.id
#  version                       = var.postgresql_version
#  public_network_access_enabled = false
#  zone                          = "1"
#  storage_mb                    = var.postgress_storage_mb
#  storage_tier                  = "P30"
#
#  sku_name = var.postgress_sku_name
#}
#resource "azurerm_postgresql_flexible_server_virtual_endpoint" "example" {
#  name              = "ekai-db-endpoint"
#  source_server_id  = azurerm_postgresql_flexible_server.ekai-db.id
#  replica_server_id = azurerm_postgresql_flexible_server.ekai-db-replica.id
#  type              = "ReadWrite"
#}


