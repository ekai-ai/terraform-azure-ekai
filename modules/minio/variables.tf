variable "image_registry" {
  description = "Container registry for MinIO images. Default `docker.io`. Override with the client's ACR (e.g. `ekaiclient1acr.azurecr.io`) for production."
  type        = string
  default     = "docker.io"
}

variable "image_repository_main" {
  description = "Repository path for the MinIO server image."
  type        = string
  default     = "bitnamilegacy/minio"
}

variable "image_repository_client" {
  description = "Repository path for the `mc` MinIO client image (used by chart helpers + bucket Job)."
  type        = string
  default     = "bitnamilegacy/minio-client"
}

variable "image_repository_console" {
  description = "Repository path for the MinIO console (object browser) image."
  type        = string
  default     = "bitnamilegacy/minio-object-browser"
}

# ── Image tags (must match what's mirrored in the ACR for this env) ────────
# Chart's own default tags drift; we override here so a mirrored tag in ACR
# is always what the pod pulls. Set to the exact tag mirrored by the
# `acr_image_mirror` module in Layer 02.
variable "image_tag_main" {
  description = "Tag for the MinIO server image. Must exist at <image_registry>/<image_repository_main>:<this>."
  type        = string
}

variable "image_tag_client" {
  description = "Tag for the `mc` client image. Must exist at <image_registry>/<image_repository_client>:<this>."
  type        = string
}

variable "image_tag_console" {
  description = "Tag for the MinIO console image. Must exist at <image_registry>/<image_repository_console>:<this>."
  type        = string
}

variable "minio_namespace" {
  description = "Kubernetes namespace where MinIO is installed."
  type        = string
  default     = "minio"
}

variable "minio_host" {
  description = "Hostname for the MinIO **API** ingress (S3 endpoint, port 9000), e.g. minio.dev.ekai.ai. Apps use this in S3_ENDPOINT."
  type        = string
}

variable "minio_console_host" {
  description = "Hostname for the MinIO **console** (web UI, port 9001), e.g. minio-console.dev.ekai.ai. Browsers visiting the API host get redirected here. If unset (empty string), defaults to `minio-console.<domain>` derived from minio_host."
  type        = string
  default     = ""
}

variable "tls_name" {
  description = "Name of the wildcard TLS secret the MinIO ingress consumes."
  type        = string
}

# ── Helm chart configuration ──────────────────────────────────────────────────

variable "chart_version" {
  description = "Bitnami MinIO Helm chart version. Pin in prod to avoid surprises."
  type        = string
  default     = "17.0.21"
}

variable "minio_mode" {
  description = "MinIO deployment mode. Use \"distributed\" for prod (≥4 replicas), \"standalone\" for dev."
  type        = string
  default     = "distributed"

  validation {
    condition     = contains(["distributed", "standalone"], var.minio_mode)
    error_message = "minio_mode must be either \"distributed\" or \"standalone\"."
  }
}

variable "minio_replicas" {
  description = "Number of MinIO StatefulSet replicas. Must be ≥ 4 when minio_mode = distributed."
  type        = number
  default     = 4
}

variable "persistence_size" {
  description = "PVC size for each MinIO pod."
  type        = string
  default     = "100Gi"
}

variable "storage_class" {
  description = "StorageClass for MinIO PVCs. Use a premium SSD class in prod."
  type        = string
  default     = "managed-premium"
}

variable "default_buckets" {
  description = "Buckets created automatically on first install."
  type        = list(string)
  default     = ["ekai-files"]
}

variable "enable_ingress" {
  description = "Expose MinIO via the nginx-ingress + TLS. Set false to keep it cluster-internal only."
  type        = bool
  default     = true
}

variable "resources" {
  description = "Kubernetes resources (requests/limits) for each MinIO pod."
  type        = any
  default = {
    requests = { cpu = "250m", memory = "1Gi" }
    limits   = { cpu = "2", memory = "4Gi" }
  }
}

# ── Tagging ───────────────────────────────────────────────────────────────────

variable "tags" {
  description = "Tags applied to the Azure DNS A record."
  type        = map(string)
  default     = {}
}
