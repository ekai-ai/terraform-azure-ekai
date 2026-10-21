terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl" # Explicit source
      version = "~> 1.14"             # Match root module's version
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}