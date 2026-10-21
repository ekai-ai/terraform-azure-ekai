variable "env_name" {
  description = "Environment name (dev/qa/prod/client-acme-prod/...). Used in workload identity display names."
  type        = string
}

variable "key_vault_name" {
  description = "Key Vault name to create. Must be globally unique within Azure (3-24 chars)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the Key Vault is created in."
  type        = string
}

variable "region" {
  description = "Azure region for the Key Vault."
  type        = string
}

variable "rbac_principal_ids" {
  description = "Extra objectIds (additional admins) to grant Key Vault Secrets Officer on top of the deploying caller, which always gets it."
  type        = list(string)
  default     = []
}

variable "aks_oidc_issuer_url" {
  description = "OIDC issuer URL of the AKS cluster (output of the aks module). Used to federate ESO's identity."
  type        = string
}

variable "eso_namespace" {
  description = "Namespace where the External Secrets Operator runs."
  type        = string
  default     = "external-secrets"
}

variable "eso_service_account_name" {
  description = "ServiceAccount name used by the ESO controller (must match the helm chart's serviceAccount.name)."
  type        = string
  default     = "external-secrets"
}

variable "secret_name" {
  description = "Name of the single master secret this vault ever stores (modules/platform's azurerm_key_vault_secret.master_self_service/master_non_self_service). Used to scope the Secrets Officer and ESO Secrets User role assignments to that one secret instead of the whole vault."
  type        = string
}
