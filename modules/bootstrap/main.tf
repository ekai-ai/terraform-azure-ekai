# ──────────────────────────────────────────────────────────────────────────
# bootstrap submodule — DNS zone + RBAC
# ──────────────────────────────────────────────────────────────────────────
# Ported from devops/azure-terraform's 01-bootstrap, with the Key Vault
# concerns moved to the cluster submodule's key_vault module call instead
# (the Key Vault is now created by Terraform, not pre-seeded by a client —
# see modules/key_vault's file header. It needs the AKS OIDC issuer URL for
# ESO's workload identity, which doesn't exist yet at this point, so it's
# created where that's available instead of here).
#
# What this submodule provisions:
#   • Azure DNS zone for this env (when manage_dns_zone = true)
#   • DNS Zone Contributor role assignment for the deploying caller(s)
#     (so cert-manager + the cicd submodule can write DNS records)
#
# What it reads (out-of-band — must exist before apply, see
# scripts/init-state-backend.sh):
#   • Resource group
# ──────────────────────────────────────────────────────────────────────────

locals {
  common_tags = merge(var.tags, {
    env       = var.env_name
    layer     = "bootstrap"
    managedBy = "terraform"
  })
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

# ── DNS zone (optional) ────────────────────────────────────────────────────
# Created when manage_dns_zone = true. After apply, delegate from the parent
# zone (`ekai.ai`) by adding NS records pointing to `output.dns_zone_name_servers`.
resource "azurerm_dns_zone" "main" {
  count               = var.manage_dns_zone ? 1 : 0
  name                = var.dns_zone
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = local.common_tags
}

data "azurerm_dns_zone" "main" {
  count               = var.manage_dns_zone ? 0 : 1
  name                = var.dns_zone
  resource_group_name = data.azurerm_resource_group.rg.name
}

locals {
  dns_zone_id           = var.manage_dns_zone ? azurerm_dns_zone.main[0].id : data.azurerm_dns_zone.main[0].id
  dns_zone_name         = var.manage_dns_zone ? azurerm_dns_zone.main[0].name : data.azurerm_dns_zone.main[0].name
  dns_zone_name_servers = var.manage_dns_zone ? azurerm_dns_zone.main[0].name_servers : []
}

# ── RBAC: DNS Zone Contributor (so the cicd submodule can manage A records,
#     cert-manager can solve DNS01 challenges via UAMI in the cluster
#     submodule) ────────────────────────────────────────────────────────────
# Split into two resources (caller + extra admins) rather than one for_each
# over a set mixing data.azurerm_client_config's value with var.rbac_principal_ids
# -- confirmed live (real terraform plan against a fresh subscription) that
# Terraform rejects a for_each set containing a data-source-derived value as
# "Invalid for_each argument ... cannot be determined until apply", even
# though this data source has no dependency on anything else in this
# configuration. Same fix as modules/key_vault's identical pattern.
resource "azurerm_role_assignment" "dns_zone_contributor_caller" {
  count                = var.manage_dns_zone ? 1 : 0
  scope                = local.dns_zone_id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  # No skip_service_principal_aad_check: confirmed live it makes Azure's API
  # reject any non-ServicePrincipal caller ("UnmatchedPrincipalType") -- see
  # modules/key_vault's identical fix for the full reasoning. The caller
  # already exists before this apply starts regardless of its type, so
  # there's no propagation race to skip the check for.
}

resource "azurerm_role_assignment" "dns_zone_contributor_extra" {
  for_each             = var.manage_dns_zone ? toset(var.rbac_principal_ids) : []
  scope                = local.dns_zone_id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = each.value
}
