variable "env_name" {
  description = "Environment identifier (dev/qa/prod/...). Used in identity and fedcred names."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that owns the AKS cluster and Key Vault."
  type        = string
}

variable "location" {
  description = "Azure region for the user-assigned managed identities."
  type        = string
}

variable "pipelines" {
  description = "List of service names to provision workload identities for. Each entry becomes one managed identity, one federated credential, one Key Vault role assignment, and one Kubernetes ServiceAccount."
  type        = list(string)
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL of the AKS cluster (output `oidc_issuer_url` of the aks module). Used as the federation issuer so the Kubernetes token-exchange succeeds."
  type        = string
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault the per-service identities need read access to (Key Vault Secrets User role)."
  type        = string
}

variable "ekai_namespace" {
  description = "Kubernetes namespace where the application workloads run (e.g. ekai-saas). Used to build the ServiceAccount OIDC subject."
  type        = string
}

variable "secret_name" {
  description = "Name of the single master secret in the vault (var.secrets_name at the root). Scopes each service's Key Vault Secrets User role assignment to that one secret instead of the whole vault."
  type        = string
}
