variable "chart_version" {
  description = "External Secrets Operator Helm chart version. Pin in prod."
  type        = string
  default     = "0.10.7"
}

variable "namespace" {
  description = "Namespace where ESO is installed."
  type        = string
  default     = "external-secrets"
}

variable "service_account_name" {
  description = "ServiceAccount name used by the ESO controller. Must match the federated identity credential's subject in the key_vault module."
  type        = string
  default     = "external-secrets"
}

variable "workload_identity_client_id" {
  description = "Client ID of the Entra ID app for ESO workload identity (output `eso_client_id` of the key_vault module)."
  type        = string
}

variable "key_vault_uri" {
  description = "Key Vault URI (https://<name>.vault.azure.net/) — output `uri` of the key_vault module."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID — output `tenant_id` of the key_vault module."
  type        = string
}

variable "cluster_secret_store_name" {
  description = "Name of the ClusterSecretStore CRD that ExternalSecrets reference."
  type        = string
  default     = "azure-keyvault"
}
