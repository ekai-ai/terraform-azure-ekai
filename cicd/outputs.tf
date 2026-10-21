# ──────────────────────────────────────────────────────────────────────────────
# cicd outputs — re-exports module.cicd's own outputs. portal_url lives here
# (not in ../outputs.tf) because it isn't real until THIS apply has run — the
# combined root doesn't deploy the application, only the platform it runs on.
#
# ArgoCD's own URL/admin credentials are already available from the combined
# root's outputs (`terraform output` in the parent directory) — ArgoCD itself
# is deployed there, not here — so they aren't duplicated in this file.
# ──────────────────────────────────────────────────────────────────────────────

output "portal_url" {
  value = module.cicd.portal_url
}

output "argocd_app_name" {
  value = module.cicd.argocd_app_name
}

output "wildcard_dns_record" {
  value = module.cicd.wildcard_dns_record
}

output "cicd_provider" {
  value = module.cicd.cicd_provider
}

output "shared_service_account_name" {
  value = module.cicd.shared_service_account_name
}
