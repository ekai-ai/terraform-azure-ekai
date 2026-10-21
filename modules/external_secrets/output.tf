output "namespace" {
  description = "Namespace where ESO is installed."
  value       = kubernetes_namespace.eso.metadata[0].name
}

output "cluster_secret_store_name" {
  description = "ClusterSecretStore name. Reference this in every ExternalSecret resource via spec.secretStoreRef.name."
  value       = var.cluster_secret_store_name
}
