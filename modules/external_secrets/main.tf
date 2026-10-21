# ── Namespace ─────────────────────────────────────────────────────────────────
resource "kubernetes_namespace" "eso" {
  metadata {
    name = var.namespace
    labels = {
      "azure.workload.identity/system" = "true"
    }
  }
}

# ── ESO controller — Helm release ─────────────────────────────────────────────
# The ServiceAccount is annotated with the workload identity client-id so
# pods running with this SA can token-exchange against Key Vault.
resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  namespace  = kubernetes_namespace.eso.metadata[0].name
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = var.chart_version

  values = [yamlencode({
    installCRDs = true

    serviceAccount = {
      create = true
      name   = var.service_account_name
      annotations = {
        "azure.workload.identity/client-id" = var.workload_identity_client_id
      }
      labels = {
        "azure.workload.identity/use" = "true"
      }
    }

    # Pod-level workload identity wiring
    podLabels = {
      "azure.workload.identity/use" = "true"
    }

    # Webhook + cert-controller sub-charts inherit the same SA labels
    webhook = {
      podLabels = {
        "azure.workload.identity/use" = "true"
      }
      serviceAccount = {
        labels = {
          "azure.workload.identity/use" = "true"
        }
      }
    }

    certController = {
      podLabels = {
        "azure.workload.identity/use" = "true"
      }
      serviceAccount = {
        labels = {
          "azure.workload.identity/use" = "true"
        }
      }
    }
  })]

  depends_on = [kubernetes_namespace.eso]
}

# ── ClusterSecretStore — points at the Key Vault, used by every ExternalSecret
# Cluster-scoped (vs namespaced SecretStore) so any service in any namespace
# can reference it without per-namespace wiring.
resource "kubectl_manifest" "cluster_secret_store" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = var.cluster_secret_store_name
    }
    spec = {
      provider = {
        azurekv = {
          authType = "WorkloadIdentity"
          vaultUrl = var.key_vault_uri
          tenantId = var.tenant_id
          serviceAccountRef = {
            name      = var.service_account_name
            namespace = var.namespace
          }
        }
      }
    }
  })

  depends_on = [helm_release.external_secrets]
}
