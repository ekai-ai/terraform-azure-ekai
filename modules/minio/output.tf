output "minio_host" {
  description = "Hostname for the MinIO ingress (only meaningful when enable_ingress = true)."
  value       = var.minio_host
}

output "minio_namespace" {
  description = "Namespace where MinIO is installed."
  value       = var.minio_namespace
}

output "minio_endpoint" {
  description = "Public endpoint when ingress is enabled, otherwise the in-cluster endpoint."
  value       = local.minio_endpoint
}

output "minio_internal_endpoint" {
  description = "In-cluster endpoint (always reachable from pods)."
  value       = local.minio_internal_endpoint
}

output "minio_root_user" {
  description = "Generated MinIO root user."
  value       = random_password.minio_root_user.result
  sensitive   = true
}

output "minio_root_password" {
  description = "Generated MinIO root password."
  value       = random_password.minio_root_password.result
  sensitive   = true
}

output "default_buckets" {
  description = "Comma-separated list of default buckets created at install time."
  value       = join(",", var.default_buckets)
}
