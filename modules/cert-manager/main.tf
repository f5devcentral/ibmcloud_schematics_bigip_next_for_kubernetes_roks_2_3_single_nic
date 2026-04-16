# ============================================================
# Cert-Manager Module
# Manages cert-manager installation including:
# - Namespace creation
# - Helm release deployment
# - CRD registration
# - Post-deployment wait for CRD availability
# ============================================================

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.25.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
  }
}

# Create cert-manager namespace
resource "kubernetes_namespace" "cert_manager" {
  count = var.enabled ? 1 : 0

  metadata {
    name = var.namespace
  }
}

# Install cert-manager via Helm
# With installCRDs=true to ensure CRDs are created during deployment
resource "helm_release" "cert_manager" {
  count = var.enabled ? 1 : 0

  name       = "cert-manager"
  repository = var.chart_repository
  chart      = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager[0].metadata[0].name
  version    = var.chart_version
  wait       = var.wait_for_deployment
  timeout    = var.timeout

  # Install CRDs as part of the Helm release
  set {
    name  = "installCRDs"
    value = "true"
  }

  # Enable server-side apply for better resource management
  set {
    name  = "featureGates"
    value = "ServerSideApply=true"
  }

  depends_on = [kubernetes_namespace.cert_manager[0]]
}

# Wait for cert-manager CRDs to be fully registered
# This ensures ClusterIssuer, Certificate, and other cert-manager CRDs
# are available before dependent resources try to use them
resource "time_sleep" "cert_manager_ready" {
  count = var.enabled ? 1 : 0

  depends_on      = [helm_release.cert_manager[0]]
  create_duration = "${var.post_deployment_delay}s"
}
