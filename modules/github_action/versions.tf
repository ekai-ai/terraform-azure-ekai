# `github` provider lives in the integrations namespace, not hashicorp.
# Required so Terraform can resolve the source address for child-module use.
terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.6.0"
    }
  }
}
