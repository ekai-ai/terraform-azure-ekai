output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config
}
output "client_id" {
  value = azurerm_user_assigned_identity.cert_manager_uami.client_id
}
output "client_certificate" {
  value = azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate
}
output "client_key" {
  value = azurerm_kubernetes_cluster.aks.kube_config[0].client_key
}
output "cluster_ca_certificate" {
  value = azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate
}
output "aks_host" {
  value = azurerm_kubernetes_cluster.aks.kube_config[0].host
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL of the AKS cluster — used as the issuer for federated identity credentials (ESO, workload identity)."
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

# Kubelet managed identity — used by ACR module to grant AcrPull, so pods
# can pull images from the client's ACR without docker creds.
output "kubelet_identity_object_id" {
  value = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}