# ── Key Vault — created by Terraform (self-service: no client-run onboarding
# step). RBAC-authorization mode, not access-policy mode, matching every
# other role assignment in this repo.
#
# purge_protection_enabled = false + the provider's
# `purge_soft_delete_on_destroy`/`recover_soft_deleted_key_vaults` features
# (see root providers.tf) are both required for self-deploy.sh/
# self-deploy-destroy.sh's destroy-then-reapply-same-name loop: with purge
# protection on, a destroyed vault's name stays reserved for the 7-day soft
# delete window and a re-apply with the same env name fails with "Vault name
# already in use".
resource "azurerm_key_vault" "main" {
  name                       = var.key_vault_name
  location                   = var.region
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  enable_rbac_authorization  = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
}

data "azurerm_client_config" "current" {}

# Caller (the SP / user running terraform) gets RBAC by default. Add more
# admins via `rbac_principal_ids` in tfvars.
locals {
  effective_principals = toset(concat(
    [data.azurerm_client_config.current.object_id],
    var.rbac_principal_ids,
  ))
}

# Without this, the root module's own key_vault_secret resources (the master
# secret, see modules/platform/main.tf) can't write to a vault Terraform just
# created in the same apply.
#
# Scoped to that one master secret's path, not the whole vault: this vault
# never holds anything else across either self-service or non-self-service
# mode (modules/platform/main.tf's master_self_service/master_non_self_service
# are the only azurerm_key_vault_secret resources in this repo, both named
# var.secrets_name). Azure Key Vault RBAC supports assigning a role scoped to
# a specific secret's path (<vault_id>/secrets/<name>) even before that secret
# exists -- the scope is a name-based string, not a reference to a live
# object -- so this doesn't introduce an apply-order dependency on the secret
# actually having been created yet.
resource "azurerm_role_assignment" "kv_secrets_officer" {
  for_each             = local.effective_principals
  scope                = "${azurerm_key_vault.main.id}/secrets/${var.secret_name}"
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = each.value
  # Skip AAD reachability check — newly-created SPs propagate slowly.
  skip_service_principal_aad_check = true
}

# ═════════════════════════════════════════════════════════════════════════════
# Workload Identity for External Secrets Operator (ESO)
# ─────────────────────────────────────────────────────────────────────────────
# ESO running inside AKS reads Key Vault secrets and syncs them into native
# Kubernetes Secret objects. We use AKS Workload Identity (OIDC federation) —
# no static secrets, no client-secret in the cluster.
# ═════════════════════════════════════════════════════════════════════════════

resource "azuread_application" "eso" {
  display_name = "ekai-eso-${var.env_name}"
}

resource "azuread_service_principal" "eso" {
  client_id = azuread_application.eso.client_id
}

resource "azuread_application_federated_identity_credential" "eso" {
  application_id = azuread_application.eso.id
  display_name   = "eso-aks-${var.env_name}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = var.aks_oidc_issuer_url
  subject        = "system:serviceaccount:${var.eso_namespace}:${var.eso_service_account_name}"
}

# Scoped to the one master secret, not the whole vault -- see
# kv_secrets_officer's comment above for why that's safe here. ESO only ever
# needs to read var.secret_name; there's nothing else in this vault for it
# to read.
resource "azurerm_role_assignment" "eso_secrets_user" {
  scope                = "${azurerm_key_vault.main.id}/secrets/${var.secret_name}"
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.eso.object_id
  # Skip the SP-AAD reachability check — newly-created SPs take 30-60s to
  # propagate through Entra. Without skip, role assignment fails with
  # "PrincipalNotFound" intermittently.
  skip_service_principal_aad_check = true
}
