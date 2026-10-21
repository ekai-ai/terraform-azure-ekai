variable "redis_namespace" {
  description = "Kubernetes namespace where Redis is installed."
  type        = string
  default     = "redis"
}

variable "chart_version" {
  # 24.1.0 matches terraform-google-ekai's verified-working version (checked
  # via `helm get values`/`MODULE LIST` against a real environment) -- this
  # version's Bitnami redis image bundles RediSearch/RedisJSON/vectorset
  # natively (/opt/bitnami/redis/lib/redis/modules/*.so, loaded via the
  # explicit `loadmodule` directives in main.tf's commonConfiguration). See
  # modules/redis/main.tf for why this replaced the redis/redis-stack-server
  # image-swap approach entirely.
  description = "Bitnami Redis Helm chart version. Pin in prod to avoid surprises."
  type        = string
  default     = "24.1.0"
}

variable "replica_count" {
  description = "Number of read-replica pods (excluding master). 3 is the prod default."
  type        = number
  default     = 3
}

variable "persistence_size" {
  description = "PVC size for each Redis pod (master and each replica)."
  type        = string
  default     = "8Gi"
}

variable "storage_class" {
  description = "StorageClass for Redis PVCs. Use a premium SSD class in prod."
  type        = string
  default     = "managed-premium"
}

variable "resources_master" {
  description = "Kubernetes resources (requests/limits) for the master pod."
  type        = any
  default = {
    requests = { cpu = "200m", memory = "512Mi" }
    limits   = { cpu = "1", memory = "1Gi" }
  }
}

variable "resources_replica" {
  description = "Kubernetes resources (requests/limits) for each replica pod."
  type        = any
  default = {
    requests = { cpu = "200m", memory = "512Mi" }
    limits   = { cpu = "1", memory = "1Gi" }
  }
}

variable "metrics_enabled" {
  description = "Deploy the redis-exporter sidecar for Prometheus scraping."
  type        = bool
  default     = true
}

variable "network_policy_enabled" {
  description = "Apply a NetworkPolicy that restricts traffic to pods within the same cluster."
  type        = bool
  default     = true
}

