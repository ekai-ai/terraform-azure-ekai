# ═════════════════════════════════════════════════════════════════════════════
# App Workload Identity
# ─────────────────────────────────────────────────────────────────────────────
# Provisions per-service Azure Workload Identity so individual application pods
# can authenticate to Azure services (Key Vault, etc.) using OIDC federation —
# no static credentials in the cluster.
#
# For each service in var.pipelines this module creates:
#   1. azurerm_user_assigned_identity      — Entra managed identity
#   2. azurerm_federated_identity_credential — OIDC federation to the AKS SA
#   3. azurerm_role_assignment             — Key Vault Secrets User on the vault
#   4. kubernetes_service_account          — annotated with the identity client_id
# ═════════════════════════════════════════════════════════════════════════════

locals {
  # Stable string-keyed map so for_each resources have deterministic addresses.
  services = { for svc in var.pipelines : svc => svc }
}

# ── 1. User-assigned managed identity (one per service) ──────────────────────
resource "azurerm_user_assigned_identity" "service" {
  for_each = local.services

  name                = "${var.env_name}-${each.key}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
}

# ── 2. Federated identity credential ─────────────────────────────────────────
# Binds the Kubernetes ServiceAccount token (issued by AKS OIDC) to the
# managed identity so the pod can exchange it for an Azure access token.
resource "azurerm_federated_identity_credential" "service" {
  for_each = local.services

  name                = "${var.env_name}-${each.key}-fedcred"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.service[each.key].id

  audience = ["api://AzureADTokenExchange"]
  issuer   = var.oidc_issuer_url
  subject  = "system:serviceaccount:${var.ekai_namespace}:${each.key}-sa"
}

# ── 3. Key Vault Secrets User role assignment ─────────────────────────────────
# Grants each managed identity read-only access to the one master secret in
# the shared vault -- scoped to that secret's path, not the whole vault (see
# modules/key_vault's kv_secrets_officer comment: this repo never puts
# anything else in this vault). Matches the GCP app identity's conditional
# secretAccessor binding (modules/platform's google_project_iam_member.
# ekai_app_secret_accessor), which was built to mirror this module's
# per-service grant but added the condition this module was missing.
# skip_service_principal_aad_check avoids transient "PrincipalNotFound" errors
# that occur during the 30-60 s Entra propagation window for newly-created
# managed identities.
resource "azurerm_role_assignment" "kv_secrets_user" {
  for_each = local.services

  scope                            = "${var.key_vault_id}/secrets/${var.secret_name}"
  role_definition_name             = "Key Vault Secrets User"
  principal_id                     = azurerm_user_assigned_identity.service[each.key].principal_id
  skip_service_principal_aad_check = true
}

# ── 4. Kubernetes ServiceAccount ──────────────────────────────────────────────
# The azure.workload.identity/client-id annotation is the bridge between the
# Kubernetes pod and the Azure managed identity. The mutating webhook injected
# by the Workload Identity controller uses it to mount the projected OIDC
# token volume.
resource "kubernetes_service_account" "service" {
  for_each = local.services

  metadata {
    name      = "${each.key}-sa"
    namespace = var.ekai_namespace

    annotations = {
      "azure.workload.identity/client-id" = azurerm_user_assigned_identity.service[each.key].client_id
    }

    labels = {
      "azure.workload.identity/use" = "true"
    }
  }
}
