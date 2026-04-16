# ============================================================
# License Module
# ============================================================
# Deploys the F5 BNK License Custom Resource
# Must be deployed after CNEInstance/FLO to ensure the License CRD exists

# Wait for License CRD to be available
resource "time_sleep" "wait_for_license_crd" {
  count           = var.enabled ? 1 : 0
  depends_on      = [var.cneinstance_dependency]
  create_duration = "10s"
}

# Create License CR in utils namespace
resource "kubernetes_manifest" "bnk_license" {
  count = var.enabled ? 1 : 0

  manifest = {
    apiVersion = "k8s.f5net.com/v1"
    kind       = "License"
    metadata = {
      name      = "bnk-license"
      namespace = var.utils_namespace
    }
    spec = {
      jwt           = var.jwt_token
      operationMode = var.license_mode
    }
  }

  depends_on = [time_sleep.wait_for_license_crd[0]]
}
