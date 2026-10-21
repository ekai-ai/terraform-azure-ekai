# ────────────────────────────────────────────────────────────────────────────
# cicd submodule variables. AKS connection details are NOT declared here --
# the root module's kubernetes/kubectl/argocd provider blocks are fed
# directly from module.cluster's / module.platform's outputs (see
# ../../providers.tf).
# ────────────────────────────────────────────────────────────────────────────

variable "env_name" {
  type = string
}

variable "region" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "secrets_name" {
  description = "Master Key Vault secret name holding DB credentials + (non-self-service only) github_token/username/email. Also the self-service customer secret Terraform generates directly when cicd_provider = \"none\"."
  type        = string
}

variable "namespace" {
  type        = string
  description = "K8s namespace where app workloads run (e.g. ekai-saas)."
}

variable "dns_zone" {
  type = string
}

variable "tls_name" {
  type = string
}

variable "cicd_provider" {
  description = <<-EOT
    CI/CD provider for building and pushing Docker images.
      github_actions — GitHub Actions workflows with OIDC → Entra app. Client
                       must pre-seed the master Key Vault secret with
                       github_token/github_username/github_email (see
                       modules/cluster's file header for the two-step apply
                       this requires now that Key Vault is Terraform-managed).
      none           — self-service client mode: no CI at all. Images come
                       from existing_image_registry_base_url (Ekai-published,
                       cross-cloud public registry); ArgoCD deploys the
                       ekai-saas Helm chart Ekai maintains instead of a
                       git-based manifest sync.
  EOT
  type        = string
  default     = "none"
  validation {
    condition     = contains(["github_actions", "none"], var.cicd_provider)
    error_message = "cicd_provider must be 'github_actions' or 'none'."
  }
}

# ── Formerly read via `data "terraform_remote_state" "cluster"` / "platform" ──
# Wired automatically from the cluster/platform submodules' outputs by the
# root module — nothing to set in tfvars for these.

variable "aks_cluster_name" {
  type = string
}

variable "acr_id" {
  type = string
}

variable "acr_login_server" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "oidc_issuer_url" {
  description = "AKS OIDC issuer URL (sourced from the cluster submodule's output) -- used for the self-service shared app identity's federated credential."
  type        = string
}

variable "cluster_secret_store_name" {
  type = string
}

# ═══════════════════════════════════════════════════════════════════════════
# github_actions path only (cicd_provider = "github_actions")
# ═══════════════════════════════════════════════════════════════════════════

variable "github_owner" {
  type    = string
  default = ""
}

variable "manifests_reponame" {
  type    = string
  default = "deployment-files"
}

variable "manifests_branch" {
  type    = string
  default = ""
}

variable "manifests_path" {
  type    = string
  default = "manifest-files"
}

variable "cd_repos" {
  type = list(object({
    name            = string
    reponame        = string
    repo_env        = string
    image_path      = optional(string, ".")
    dockerfile      = optional(string, "Dockerfile")
    deployment_yaml = string
  }))
  default = []
}

variable "registries" {
  type = object({
    azure = object({ enabled = bool })
    dockerhub = object({
      enabled   = bool
      namespace = string
    })
    aws_ecr = object({
      enabled      = bool
      registry_url = string
      region       = string
    })
  })
  default = {
    azure     = { enabled = true }
    dockerhub = { enabled = false, namespace = "" }
    aws_ecr   = { enabled = false, registry_url = "", region = "" }
  }
}

variable "dockerhub_username" {
  type      = string
  default   = ""
  sensitive = true
}

variable "dockerhub_token" {
  type      = string
  default   = ""
  sensitive = true
}

variable "aws_ecr_access_key_id" {
  type      = string
  default   = ""
  sensitive = true
}

variable "aws_ecr_secret_access_key" {
  type      = string
  default   = ""
  sensitive = true
}

# ═══════════════════════════════════════════════════════════════════════════
# cicd_provider = "none" (self-service) only
# ═══════════════════════════════════════════════════════════════════════════

variable "existing_image_registry_base_url" {
  description = "Container registry base URL the ekai-saas chart pulls app images from (cicd_provider = \"none\" only), e.g. \"public.ecr.aws/s7m9t1b0\"."
  type        = string
  default     = ""
}

variable "helm_chart_repo_url" {
  description = "OCI registry Ekai publishes the ekai-saas chart to (cicd_provider = \"none\" only), e.g. \"public.ecr.aws/s7m9t1b0/ekai-helm\" — bare host+path, no \"oci://\" prefix and no chart name suffix. Expected public — no client credentials needed."
  type        = string
  default     = ""
}

variable "helm_chart_version" {
  description = "Chart version to deploy (cicd_provider = \"none\" only). Defaults to \"*\" — ArgoCD always tracks and auto-syncs whatever version is latest in the Helm repo. Set an exact version to pin instead."
  type        = string
  default     = "*"
}

variable "image_tag" {
  description = "Application image tag to deploy (cicd_provider = \"none\" only) — passed through as the ekai-saas chart's imageTag."
  type        = string
  default     = "latest"
}

variable "ingress_class_name" {
  type    = string
  default = "nginx"
}

variable "shared_service_account_name" {
  description = "ServiceAccount every service runs as (cicd_provider = \"none\" only). Must match the ekai-saas Helm chart's serviceAccountName value."
  type        = string
  default     = "ekai-app-sa"
}

variable "tags" {
  type    = map(string)
  default = {}
}
