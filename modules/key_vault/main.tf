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
#
# Split into two resources instead of one for_each over
# toset(concat([data.azurerm_client_config.current.object_id], var.rbac_principal_ids)):
# confirmed live (real `terraform plan` against a fresh subscription, not
# just `terraform validate`, which doesn't catch this) that mixing a
# data-source-derived value into a for_each set fails with "Invalid for_each
# argument ... values derived from resource attributes that cannot be
# determined until apply" -- even though data.azurerm_client_config has
# nothing to do with any resource in this configuration. Terraform's error
# message itself recommends exactly this fix: keys that are known statically
# at plan time (var.rbac_principal_ids, plain tfvars input) in the for_each,
# and the single data-source-derived grant as its own non-for_each resource.
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
resource "azurerm_role_assignment" "kv_secrets_officer_caller" {
  scope                = "${azurerm_key_vault.main.id}/secrets/${var.secret_name}"
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
  # No skip_service_principal_aad_check here: confirmed live that setting it
  # true makes Azure's API assume the principal IS a ServicePrincipal and
  # reject any other type ("UnmatchedPrincipalType") -- the caller running
  # Terraform can be a plain user (local testing) or a service principal
  # (scripts/self-deploy.sh's deployer SP in the real flow), and either way
  # it already exists and is already fully propagated through Entra before
  # this apply even starts, so there's no "freshly created, not yet visible"
  # race to skip the check for in the first place. Only genuinely
  # freshly-created-within-this-apply identities (the ESO SP below, the
  # per-service UAMIs in modules/app_workload_identity) need the skip.
}

resource "azurerm_role_assignment" "kv_secrets_officer_extra" {
  for_each             = toset(var.rbac_principal_ids)
  scope                = "${azurerm_key_vault.main.id}/secrets/${var.secret_name}"
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = each.value
  # Same reasoning as kv_secrets_officer_caller above -- these are
  # pre-existing admin principals (of unknown type: user, group, or SP)
  # passed in via tfvars, not created by this apply.
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
