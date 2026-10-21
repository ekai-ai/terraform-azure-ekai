# Required because the kubectl provider is not in the default registry
# namespace. Terraform must know to fetch `gavinbunney/kubectl` (not
# `hashicorp/kubectl`) -- same fix as modules/cert-manager and
# modules/external_secrets.
terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }
  }
}
