output "argocd_admin_password" {
  description = "The ArgoCD admin password."
  value       = var.argocd_admin_password_hashed
  sensitive   = true
}

output "argocd_namespace" {
  description = "The Kubernetes namespace where ArgoCD is deployed."
  value       = kubernetes_namespace.argocd.metadata[0].name
}

# load_balancer_{hostname,ip} outputs removed — they read from the ArgoCD
# Ingress's status which is empty during apply. The wildcard A record in
# Layer 04 (modules/microservices_CD) handles `argocd.<env>.ekai.ai` via
# the nginx-ingress LB Service IP.