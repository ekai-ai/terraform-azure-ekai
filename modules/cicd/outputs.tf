output "argocd_app_name" {
  value = module.microservices_CD.argocd_app_name
}

output "wildcard_dns_record" {
  value = module.microservices_CD.wildcard_dns_record
}

output "portal_url" {
  description = "The application's public URL (cicd_provider = \"none\" only)."
  value       = local.self_service ? "https://portal.${var.dns_zone}" : null
}

output "cicd_provider" {
  value = var.cicd_provider
}

output "shared_service_account_name" {
  value = var.shared_service_account_name
}
