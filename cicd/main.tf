# ──────────────────────────────────────────────────────────────────────────────
# cicd — separate apply/state from the combined bootstrap+cluster+platform
# root one directory up (see ../main.tf's file header for the full reasoning).
# In short: the argocd Terraform provider's `password` field must be a value
# Terraform already knows before apply — it cannot be a same-apply managed
# resource attribute. module.platform's freshly-generated ArgoCD admin
# password (self-service) is exactly such an attribute, so this apply has to
# run separately, AFTER the combined one has already finished and written
# that password to state.
# ──────────────────────────────────────────────────────────────────────────────

module "cicd" {
  source = "../modules/cicd"

  env_name            = var.env_name
  region              = var.region
  resource_group_name = var.resource_group_name
  secrets_name        = local.secrets_name
  namespace           = var.namespace
  dns_zone            = var.dns_zone
  tls_name            = coalesce(var.tls_name, "${var.env_name}-ekai-wildcard-tls")
  cicd_provider       = var.cicd_provider
  tags                = var.tags

  github_owner              = var.github_owner
  manifests_reponame        = var.manifests_reponame
  manifests_branch          = var.manifests_branch
  manifests_path            = var.manifests_path
  cd_repos                  = var.cd_repos
  registries                = var.registries
  dockerhub_username        = var.dockerhub_username
  dockerhub_token           = var.dockerhub_token
  aws_ecr_access_key_id     = var.aws_ecr_access_key_id
  aws_ecr_secret_access_key = var.aws_ecr_secret_access_key

  existing_image_registry_base_url = var.existing_image_registry_base_url
  helm_chart_repo_url              = var.helm_chart_repo_url
  helm_chart_version               = var.helm_chart_version
  image_tag                        = var.image_tag
  ingress_class_name               = var.ingress_class_name
  shared_service_account_name      = var.shared_service_account_name

  # formerly `data "terraform_remote_state" "cluster"` / "platform" in the
  # original 04-cicd/main.tf — now reads the combined root's state instead
  aks_cluster_name          = data.terraform_remote_state.combined.outputs.aks_cluster_name
  acr_id                    = data.terraform_remote_state.combined.outputs.acr_id
  acr_login_server          = data.terraform_remote_state.combined.outputs.acr_login_server
  key_vault_id              = local.key_vault_id
  oidc_issuer_url           = data.terraform_remote_state.combined.outputs.oidc_issuer_url
  cluster_secret_store_name = data.terraform_remote_state.combined.outputs.cluster_secret_store_name
}
