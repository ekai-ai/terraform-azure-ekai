output "argocd_app_name" {
  description = "ArgoCD application name."
  value       = argocd_application.ekai_frontend.metadata[0].name
}

output "wildcard_dns_record" {
  description = "Wildcard A record FQDN — `*.<dns_zone>` resolving to the nginx-ingress LB IP."
  value       = "*.${var.dns_zone}"
}

output "nginx_ingress_lb_ip" {
  description = "Public IP of the nginx-ingress controller LoadBalancer. All service hostnames resolve to this IP via the wildcard DNS record."
  value       = data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].ip
}
