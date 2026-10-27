output "id" {
  description = "Key Vault resource ID — pass to modules that read/write secrets."
  value       = azurerm_key_vault.main.id
}

output "name" {
  description = "Key Vault name."
  value       = azurerm_key_vault.main.name
}

output "uri" {
  description = "Key Vault URI (https://<name>.vault.azure.net/) — used by ESO ClusterSecretStore."
  value       = azurerm_key_vault.main.vault_uri
}

output "tenant_id" {
  description = "Azure AD tenant ID — used by ESO to authenticate."
  value       = azurerm_key_vault.main.tenant_id
}

output "eso_client_id" {
  description = "Client ID of the user-assigned managed identity for ESO workload identity. The external_secrets module annotates the ESO ServiceAccount with this."
  value       = azurerm_user_assigned_identity.eso.client_id
}
