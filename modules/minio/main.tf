# ── Auth ──────────────────────────────────────────────────────────────────────
resource "random_password" "minio_root_user" {
  length  = 16
  upper   = true
  lower   = true
  numeric = true
  special = false

  keepers = {
    namespace = var.minio_namespace
  }
}

resource "random_password" "minio_root_password" {
  length  = 32
  upper   = true
  lower   = true
  numeric = true
  special = false # base64-safe; avoids env-file quoting headaches

  keepers = {
    namespace = var.minio_namespace
  }
}

locals {
  # If caller didn't provide a console hostname, derive one by prepending
  # `console.` to the API hostname. e.g. minio.client1.ekai.ai → console.minio.client1.ekai.ai
  # Caller can override per-env in tfvars if a different convention is wanted.
  minio_console_host = var.minio_console_host != "" ? var.minio_console_host : "console.${var.minio_host}"
}

# ── Namespace ─────────────────────────────────────────────────────────────────
resource "kubernetes_namespace" "minio" {
  metadata {
    name = var.minio_namespace
  }
}

# ═════════════════════════════════════════════════════════════════════════════
# MinIO Helm release — distributed mode for prod (≥4 replicas)
# ═════════════════════════════════════════════════════════════════════════════

resource "helm_release" "minio" {
  name       = "minio"
  namespace  = kubernetes_namespace.minio.metadata[0].name
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "minio"
  version    = var.chart_version

  values = [yamlencode({
    # Bitnami changed its image distribution model (Aug 2025): free-tier
    # images moved to `bitnamilegacy/` namespace; the chart's pinned tags
    # under `bitnami/` are removed → ImagePullBackOff. Override image
    # repository to use `bitnamilegacy/` until Bitnami chart catches up,
    # OR migrate to upstream MinIO chart (https://github.com/minio/minio/tree/master/helm/minio)
    # for long-term stability — `minio/minio` images managed by MinIO Inc.
    image = {
      registry   = var.image_registry
      repository = var.image_repository_main
      tag        = var.image_tag_main
    }
    # `mc` client image (used by chart's provisioning helpers + bucket Job).
    clientImage = {
      registry   = var.image_registry
      repository = var.image_repository_client
      tag        = var.image_tag_client
    }
    # Console (web UI) image — separate Deployment in distributed mode.
    console = {
      image = {
        registry   = var.image_registry
        repository = var.image_repository_console
        tag        = var.image_tag_console
      }
    }
    # Bitnami chart's image-validity check rejects non-`bitnami/` images.
    global = {
      security = {
        allowInsecureImages = true
      }
    }

    mode = var.minio_mode

    statefulset = {
      replicaCount  = var.minio_replicas
      drivesPerNode = 1
    }

    auth = {
      rootUser     = random_password.minio_root_user.result
      rootPassword = random_password.minio_root_password.result
    }

    persistence = {
      enabled      = true
      size         = var.persistence_size
      storageClass = var.storage_class
    }

    service = {
      type = "ClusterIP"
    }

    # API ingress — `minio.<env>.ekai.ai` → port 9000 (S3 API)
    apiIngress = {
      enabled          = var.enable_ingress
      ingressClassName = "nginx"
      # NOTE: NO `cert-manager.io/cluster-issuer` annotation here.
      # The wildcard cert (`*.<dns_zone>`) issued in the cert-manager Terraform
      # module is reflected into this namespace as `<env>-ekai-wildcard-tls`.
      # Adding the annotation would make cert-manager auto-create a per-Ingress
      # Certificate that overwrites the wildcard secret with a single-host cert
      # → all other Ingresses fall back to fake fallback cert. Always rely on
      # the reflected secret instead.
      annotations = {
        "nginx.ingress.kubernetes.io/proxy-body-size"    = "1024m"
        "nginx.ingress.kubernetes.io/proxy-read-timeout" = "600"
        "nginx.ingress.kubernetes.io/proxy-send-timeout" = "600"
      }
      hostname = var.minio_host
      tls      = true
      extraTls = [{
        secretName = var.tls_name
        hosts      = [var.minio_host]
      }]
    }

    # Console (web UI) ingress — `<console_host>` → port 9001 (browser UI)
    # Without this, MinIO server-side redirects browsers from the API URL to
    # `:9001` which isn't exposed publicly. Separate hostname for the console
    # is the cleanest fix.
    ingress = {
      enabled          = var.enable_ingress
      ingressClassName = "nginx"
      # NOTE: NO `cert-manager.io/cluster-issuer` annotation here.
      # The wildcard cert (`*.<dns_zone>`) issued in the cert-manager Terraform
      # module is reflected into this namespace as `<env>-ekai-wildcard-tls`.
      # Adding the annotation would make cert-manager auto-create a per-Ingress
      # Certificate that overwrites the wildcard secret with a single-host cert
      # → all other Ingresses fall back to fake fallback cert. Always rely on
      # the reflected secret instead.
      annotations = {
        "nginx.ingress.kubernetes.io/proxy-body-size"    = "1024m"
        "nginx.ingress.kubernetes.io/proxy-read-timeout" = "600"
        "nginx.ingress.kubernetes.io/proxy-send-timeout" = "600"
      }
      hostname = local.minio_console_host
      tls      = true
      extraTls = [{
        secretName = var.tls_name
        hosts      = [local.minio_console_host]
      }]
    }

    # `defaultBuckets` is NOT supported in distributed mode (Bitnami chart
    # restriction — see https://github.com/bitnami/charts/issues). Provisioning
    # is done via the `kubernetes_job.minio_buckets` resource below, which runs
    # `mc mb` against the live MinIO API once Helm release is healthy.

    extraEnvVars = [
      { name = "MINIO_BROWSER", value = "on" },
      { name = "MINIO_PROMETHEUS_AUTH_TYPE", value = "public" },
      # Tell MinIO: my public console URL is HTTPS at this host (not :9001).
      # Otherwise it issues 307 redirects to `:9001` which fails publicly.
      { name = "MINIO_BROWSER_REDIRECT_URL", value = "https://${local.minio_console_host}" },
      # Same for API — public URL stops MinIO from emitting localhost-style
      # presigned URLs.
      { name = "MINIO_SERVER_URL", value = "https://${var.minio_host}" }
    ]

    metrics = {
      serviceMonitor = {
        enabled = false
      }
    }

    resources = var.resources
  })]

  depends_on = [kubernetes_namespace.minio]
}

# ── Bucket provisioning job (replaces unsupported defaultBuckets) ─────────────
# Distributed mode doesn't accept `defaultBuckets`. We run a one-shot Job
# post-Helm-install that uses `mc` (MinIO client) to create each bucket.
# Idempotent: `mc mb --ignore-existing` returns 0 if bucket already exists.
resource "kubernetes_job" "minio_buckets" {
  metadata {
    name      = "minio-bucket-init"
    namespace = kubernetes_namespace.minio.metadata[0].name
  }

  spec {
    backoff_limit = 4
    template {
      metadata {
        labels = { app = "minio-bucket-init" }
      }
      spec {
        restart_policy = "OnFailure"
        container {
          name    = "mc"
          image   = "minio/mc:RELEASE.2024-10-29T15-34-59Z"
          command = ["/bin/sh", "-c"]
          args = [
            <<-EOT
              set -eu
              mc alias set local http://minio.${var.minio_namespace}.svc.cluster.local:9000 \
                "$ROOT_USER" "$ROOT_PASSWORD"
              for B in ${join(" ", var.default_buckets)}; do
                mc mb --ignore-existing "local/$B"
                echo "✅ bucket ready: $B"
              done
            EOT
          ]
          env {
            name = "ROOT_USER"
            value_from {
              secret_key_ref {
                name = "minio"
                key  = "root-user"
              }
            }
          }
          env {
            name = "ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = "minio"
                key  = "root-password"
              }
            }
          }
        }
      }
    }
  }

  wait_for_completion = true
  timeouts {
    create = "5m"
  }

  depends_on = [helm_release.minio]
}

# DNS A records for `minio.<env>.ekai.ai` and `console.minio.<env>.ekai.ai`
# are NOT created here. The wildcard A record `*.<dns_zone>` in Layer 04
# (modules/microservices_CD) reads the nginx-ingress LB Service IP directly
# (always populated as soon as the nginx Service exists) and covers BOTH
# minio hosts. Per-Ingress LB-IP lookups would race against Ingress status
# propagation and fail with "empty list of object" during apply.

# Connection details flow OUT via outputs — they are merged into the per-service
# AWS Secrets Manager secrets created by the github_action module (under
# `<env>-ekai-<repo>-env`), not stored as a separate top-level secret.
locals {
  minio_internal_endpoint = "http://minio.${var.minio_namespace}.svc.cluster.local:9000"
  minio_endpoint          = var.enable_ingress ? "https://${var.minio_host}" : local.minio_internal_endpoint
}
