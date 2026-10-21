variable "env" {
  description = "Environment name (e.g., dev, test, prod)."
  type        = string
}

variable "source_type" {
  description = <<-EOT
    ArgoCD Application source:
      "git"  — Ekai-internal / cicd_provider != "none" envs. Deploys from the
               deployment-files git repo (path = manifests_path,
               target_revision = manifests_branch).
      "helm" — self-service clients (cicd_provider = "none"). No git/CI
               access needed — deploys the versioned ekai-saas Helm chart
               Ekai publishes (see helm_repo_url/helm_chart_version).
  EOT
  type        = string
  default     = "git"
  validation {
    condition     = contains(["git", "helm"], var.source_type)
    error_message = "source_type must be 'git' or 'helm'."
  }
}

variable "github_owner" {
  description = "GitHub org/user that owns the manifests repository (source_type = \"git\" only)."
  type        = string
  default     = ""
}

variable "github_username" {
  description = "GitHub username used for ArgoCD repository credentials (source_type = \"git\" only)."
  type        = string
  default     = ""
}

variable "github_token" {
  description = "GitHub PAT used by ArgoCD to clone the manifests repository (source_type = \"git\" only)."
  type        = string
  sensitive   = true
  default     = ""
}

variable "manifests_reponame" {
  description = "Name of the Kubernetes manifests repository that ArgoCD syncs from (source_type = \"git\" only)."
  type        = string
  default     = "deployment-files"
}

variable "manifests_branch" {
  description = "Branch of the manifests repository that ArgoCD tracks (source_type = \"git\" only)."
  type        = string
  default     = ""
}

variable "manifests_path" {
  description = "Path inside the manifests repo where service YAMLs live (source_type = \"git\" only)."
  type        = string
  default     = "manifest-files"
}

variable "helm_repo_url" {
  description = "OCI registry Ekai publishes the ekai-saas chart to (source_type = \"helm\" only), e.g. \"public.ecr.aws/s7m9t1b0/ekai-helm\" — bare host+path, no \"oci://\" prefix and no chart name suffix (that's helm_chart_name). Expected public — no client credentials needed."
  type        = string
  default     = ""
}

variable "helm_chart_name" {
  description = "Chart name to deploy from helm_repo_url (source_type = \"helm\" only)."
  type        = string
  default     = "ekai-saas"
}

variable "helm_chart_version" {
  description = "Chart version to deploy (source_type = \"helm\" only). Defaults to \"*\" — ArgoCD always tracks and auto-syncs whatever version is latest in the Helm repo. Set an exact version to pin instead."
  type        = string
  default     = "*"
}

variable "helm_values" {
  description = "Raw YAML values passed to the chart (source_type = \"helm\" only)."
  type        = string
  default     = ""
}

variable "namespace" {
  description = "Kubernetes namespace where the microservices are deployed."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that owns the DNS zone used for public ingress records."
  type        = string
}

variable "dns_zone" {
  description = "DNS zone where the wildcard A record is created (e.g. knowledge.ekai.ai)."
  type        = string
}

variable "tags" {
  description = "Tags applied to Azure resources created by this module."
  type        = map(string)
  default     = {}
}
