# `argocd` provider lives in the argoproj-labs namespace, not hashicorp.
# Required so Terraform can resolve the source address for child-module use.
terraform {
  required_providers {
    argocd = {
      source  = "argoproj-labs/argocd"
      version = "~> 7.11.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }
  }
}
