# ── Per-service identity client IDs ──────────────────────────────────────────
# Map of service_name => client_id. Useful when callers need to pass a
# specific identity client ID to another module (e.g. to annotate an external
# Helm chart's ServiceAccount or to push it into a secret).
output "identity_client_ids" {
  description = "Map of service name to managed identity client ID (Entra application/client ID)."
  value       = { for svc, _ in local.services : svc => azurerm_user_assigned_identity.service[svc].client_id }
}

# ── Per-service identity principal IDs ───────────────────────────────────────
# Map of service_name => principal_id (object ID). Useful for additional role
# assignments that callers want to manage outside this module.
output "identity_principal_ids" {
  description = "Map of service name to managed identity principal ID (Azure AD object ID). Use for additional role assignments."
  value       = { for svc, _ in local.services : svc => azurerm_user_assigned_identity.service[svc].principal_id }
}

# ── Per-service identity resource IDs ────────────────────────────────────────
output "identity_ids" {
  description = "Map of service name to managed identity resource ID. Use to assign the identity to AKS node pools or VMs."
  value       = { for svc, _ in local.services : svc => azurerm_user_assigned_identity.service[svc].id }
}

# ── Per-service ServiceAccount names ─────────────────────────────────────────
# Callers can reference these to build ArgoCD or Helm values without
# hard-coding the naming convention.
output "service_account_names" {
  description = "Map of service name to Kubernetes ServiceAccount name created in var.ekai_namespace."
  value       = { for svc, _ in local.services : svc => kubernetes_service_account.service[svc].metadata[0].name }
}
