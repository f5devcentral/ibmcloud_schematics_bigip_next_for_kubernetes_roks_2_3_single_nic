# ============================================================
# Provider Configuration for Root Module
# IBM Cloud OpenShift Cluster with F5 BNK Orchestrator
# ============================================================

# IBM Provider - for creating infrastructure
provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.cluster_region
}

# ============================================================
# Dynamic Cluster Authentication (Recommended Approach)
# ============================================================
# Fetch cluster credentials dynamically from IBM Cloud
# instead of relying on manually downloaded kubeconfig files
#
# This data source retrieves host, token, and CA certificate
# from the cluster and passes them to Kubernetes/Helm providers
#
# Benefits:
# - No kubeconfig files on disk
# - Works in CI/CD pipelines without CLI tools
# - Terraform-native credentials management
# - Reproducible across environments
# ============================================================

data "ibm_container_cluster_config" "cluster_config" {
  count             = var.create_cluster || var.deploy_bnk ? 1 : 0
  cluster_name_id   = var.create_cluster ? module.cluster.cluster_id : var.cluster_id_existing
  region            = var.cluster_region
}

# ============================================================
# Kubernetes Provider - Dynamic Authentication
# ============================================================
# Uses credentials fetched from ibm_container_cluster_config
# instead of reading from kubeconfig file
# Configured only when cluster config is available
# ============================================================

provider "kubernetes" {
  host                   = try(data.ibm_container_cluster_config.cluster_config[0].host, "")
  token                  = try(data.ibm_container_cluster_config.cluster_config[0].token, "")
  cluster_ca_certificate = try(base64decode(data.ibm_container_cluster_config.cluster_config[0].ca_certificate), null)
}

# ============================================================
# Helm Provider - Dynamic Authentication
# ============================================================
# Uses Kubernetes provider credentials for Helm deployments
# Configured only when cluster config is available
# ============================================================

provider "helm" {
  kubernetes {
    host                   = try(data.ibm_container_cluster_config.cluster_config[0].host, "")
    token                  = try(data.ibm_container_cluster_config.cluster_config[0].token, "")
    cluster_ca_certificate = try(base64decode(data.ibm_container_cluster_config.cluster_config[0].ca_certificate), null)
  }
}

# ============================================================
# Other Providers (Unchanged)
# ============================================================

provider "null" {}

provider "local" {}

provider "http" {}
