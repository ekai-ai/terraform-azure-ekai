variable "argocd_namespace" {
  description = "Kubernetes namespace where ArgoCD is installed."
  type        = string
}

variable "argocd_admin_password_hashed" {
  description = "Bcrypt hash of the ArgoCD admin password (passed to the argo-cd Helm chart)."
  type        = string
  sensitive   = true
}

variable "argocd_ingress_host" {
  description = "Hostname used by the ArgoCD server ingress (e.g. argocd.knowledge.ekai.ai)."
  type        = string
}

variable "tls_name" {
  description = "Name of the wildcard TLS secret that the ArgoCD ingress consumes."
  type        = string
}
