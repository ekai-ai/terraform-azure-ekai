# ──────────────────────────────────────────────────────────────────────────
# Reloader (stakater) — auto-restart Deployments when their referenced
# Secret/ConfigMap changes.
#
# Why:
#   Pod env vars from `envFrom: secretRef` are populated at pod startup. When
#   ESO syncs a new value from Azure Key Vault into the K8s Secret, existing
#   pods do NOT pick up the change automatically — they continue with stale
#   env vars until restarted.
#
# Reloader watches K8s Secrets/ConfigMaps and triggers a `kubectl rollout
# restart` on any Deployment annotated with `reloader.stakater.com/auto: "true"`
# (or specific `secret.reloader.stakater.com/reload: "<secret-names>"`).
#
# End-to-end auto-sync flow (with Reloader):
#   1. Operator updates KV secret → ESO syncs (≤1m) → K8s Secret updates
#   2. Reloader detects K8s Secret change → triggers Deployment rollout
#   3. New pods start with fresh env vars
#   Total latency: ~1-2 min from KV update to pods running new values.
# ──────────────────────────────────────────────────────────────────────────

resource "kubernetes_namespace" "reloader" {
  metadata {
    name = "reloader"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "platform"
    }
  }
}

resource "helm_release" "reloader" {
  name       = "reloader"
  namespace  = kubernetes_namespace.reloader.metadata[0].name
  repository = "https://stakater.github.io/stakater-charts"
  chart      = "reloader"
  version    = var.chart_version

  values = [yamlencode({
    reloader = {
      # Watch resources across ALL namespaces (so Deployments in ekai-saas
      # are covered without per-namespace install).
      watchGlobally = true

      deployment = {
        resources = {
          requests = { cpu = "10m", memory = "32Mi" }
          limits   = { cpu = "100m", memory = "128Mi" }
        }
      }
    }
  })]

  depends_on = [kubernetes_namespace.reloader]
}
