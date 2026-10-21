# ──────────────────────────────────────────────────────────────────────────────
# examples/self-deploy/cicd/outputs.tf — re-exports every one of
# ../../../cicd/outputs.tf's outputs as module.cicd.X.
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
