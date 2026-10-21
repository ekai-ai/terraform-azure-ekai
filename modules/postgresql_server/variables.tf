variable "resource_group_name" {
  description = "Resource group that owns the PostgreSQL Flexible Server."
  type        = string
}

variable "region" {
  description = "Azure region for the PostgreSQL Flexible Server."
  type        = string
}

variable "env_name" {
  description = "Environment identifier (knowledge, beta, test, ...) used in resource naming."
  type        = string
}

variable "subnet_id" {
  description = "ID of the delegated private subnet where the server is injected."
  type        = string
}

variable "vnet_id" {
  description = "ID of the VNet, used for the private DNS zone VNet link."
  type        = string
}

variable "postgresql_version" {
  description = "PostgreSQL major version (e.g. \"15\")."
  type        = string
}

variable "postgres_flexible_server_sku_name" {
  description = "SKU for the PostgreSQL Flexible Server (e.g. B_Standard_B2ms, GP_Standard_D2s_v3)."
  type        = string
}

variable "postgres_flexible_server_storage_mb" {
  description = "Storage size in MB for the PostgreSQL Flexible Server."
  type        = number
}

variable "enable_ha" {
  description = "Enable PostgreSQL high availability (SameZone standby replica)."
  type        = bool
  default     = true
}

variable "backend_db_name" {
  description = "Database name for the backend service."
  type        = string
}

variable "backend_db_username" {
  description = "Username for the backend database role."
  type        = string
  sensitive   = true
}

variable "backend_db_password" {
  description = "Password for the backend database role."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags applied to the PostgreSQL server and related resources."
  type        = map(string)
  default     = {}
}
