# Submodule note: provider "azurerm" {} configuration now lives only in the
# root module's providers.tf (a submodule cannot declare a provider
# configuration block of its own) — see ../../providers.tf.
#
# required_providers is kept here too — harmless, and documents this
# submodule's own provider requirements independent of root.

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.9.0"
    }
  }
}
