variable "github_owner" {
  description = "GitHub org/user that owns the application and manifests repositories."
  type        = string
}

variable "github_token" {
  description = "GitHub PAT with repo + workflow scope; pushed as an environment secret so workflows can check out the manifests repo."
  type        = string
  sensitive   = true
}

variable "github_username" {
  description = "GitHub username for git commit attribution in CI workflows."
  type        = string
}

variable "github_email" {
  description = "GitHub email for git commit attribution in CI workflows."
  type        = string
}

variable "manifests_reponame" {
  description = "Name of the Kubernetes manifests repository."
  type        = string
}

variable "manifests_branch" {
  description = "Branch of the manifests repository that workflows commit image updates to."
  type        = string
}

variable "external_acr_id" {
  description = "If set (non-null), skip creating ACR + AcrPull internally — use this existing ACR ID for AcrPush role assignment. Used by the layered architecture (Layer 04) where ACR lives in Layer 02. Set to null for legacy monolith."
  type        = string
  default     = null
}

variable "external_acr_login_server" {
  description = "Required if `external_acr_id` is set. ACR login server (e.g. ekaiclient1acr.azurecr.io) — used for AZURE_ACR_LOGIN_SERVER env-secret."
  type        = string
  default     = null
}

variable "manifests_path" {
  description = "Path inside the manifests repo where service YAMLs live. Prepended to each cd_repos[*].deployment_yaml (which is now just a filename)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that owns the AKS cluster and the ACR created here."
  type        = string
}

variable "region" {
  description = "Azure region for the ACR."
  type        = string
}

variable "env_name" {
  description = "Environment identifier (knowledge, beta, test, ...). Used in ACR name and Entra app display name."
  type        = string
}

variable "aks_name" {
  description = "Name of the AKS cluster that will pull images from this ACR (used to grant AcrPull to the kubelet identity)."
  type        = string
}

variable "registries" {
  description = "Container registries to push the built image to. Azure ACR is created by Terraform when azure.enabled = true; DockerHub and AWS ECR are external — only GitHub secrets are provisioned."
  type = object({
    azure = object({
      enabled = bool
    })
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
}

variable "dockerhub_username" {
  description = "DockerHub username for `docker login` (only used when registries.dockerhub.enabled)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "dockerhub_token" {
  description = "DockerHub access token (only used when registries.dockerhub.enabled)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_ecr_access_key_id" {
  description = "AWS access key ID used by the workflow to authenticate to ECR (only used when registries.aws_ecr.enabled)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_ecr_secret_access_key" {
  description = "AWS secret access key used by the workflow to authenticate to ECR (only used when registries.aws_ecr.enabled)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "cd_repos" {
  description = "List of application repos to generate GitHub Actions CD workflows, ACR auth secrets, and federated Entra credentials for."
  type = list(object({
    name            = string                         # service name (also used as image name)
    reponame        = string                         # GitHub repo name in github_owner
    repo_env        = string                         # GitHub Environment name (holds ACR/OIDC/Slack secrets)
    image_path      = optional(string, ".")          # build context directory (where docker build runs)
    dockerfile      = optional(string, "Dockerfile") # Dockerfile filename, relative to image_path
    deployment_yaml = string                         # path inside manifests repo to patch image tag
  }))
  default = []
}

