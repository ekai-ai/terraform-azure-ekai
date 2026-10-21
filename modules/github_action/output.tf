output "acr_login_server" {
  description = "Azure ACR login server. null when registries.azure.enabled = false."
  value       = try(azurerm_container_registry.acr[0].login_server, null)
}

output "github_actions_client_id" {
  description = "Entra app client ID used by GitHub Actions for ACR push via OIDC. null when registries.azure.enabled = false."
  value       = try(azuread_application.github_actions[0].client_id, null)
}

output "primary_image_prefix" {
  description = "Registry prefix that manifests are patched with (Azure > AWS ECR > DockerHub in priority order)."
  value       = local.primary_image_prefix
}

# Per-service env Key Vault secrets are NOT created by Terraform — they are
# entirely client-managed (post-deploy manual step). See CLIENT-HANDOVER-AZURE.md
# for the copy-paste workflow.
