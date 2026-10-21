# Required because the kubectl provider is not in the default registry namespace.
# Terraform must know to fetch `gavinbunney/kubectl` (not `hashicorp/kubectl`).
terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }
  }
}
