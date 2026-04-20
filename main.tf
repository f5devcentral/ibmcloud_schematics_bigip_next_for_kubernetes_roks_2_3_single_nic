# ============================================================
# Root Terraform Configuration
# IBM Cloud OpenShift Cluster with F5 BNK Orchestrator
# ============================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.60.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.25.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.0.0"
    }
  }
}

# Provider configurations are now in providers.tf
# This separation allows for cleaner organization and easier maintenance


module "cluster" {
  source = "./modules/cluster"

  # IBM Cloud Configuration
  ibmcloud_api_key = var.ibmcloud_api_key
  cluster_region   = var.cluster_region
  resource_group   = var.resource_group

  # Feature Flags
  create_cluster         = var.create_cluster
  create_client_vpc      = var.create_client_vpc
  create_jumphost        = var.create_jumphost
  create_transit_gateway = var.create_transit_gateway
  create_cos_instance    = var.create_cos_instance

  # Cluster VPC Configuration
  cluster_vpc_name = var.cluster_vpc_name

  # Client VPC Configuration
  client_vpc_name      = var.client_vpc_name
  client_vpc_region    = var.client_vpc_region
  client_jumphost_name = var.client_jumphost_name
  ssh_key_name         = var.ssh_key_name

  # Transit Gateway Configuration
  transit_gateway_name = var.transit_gateway_name

  # Cloud Object Storage Configuration
  cos_instance_name = var.cos_instance_name

  # OpenShift Cluster Configuration
  openshift_cluster_name = var.openshift_cluster_name
  workers_per_zone       = var.workers_per_zone
  min_worker_vcpu_count  = var.min_worker_vcpu_count
  min_worker_memory_gb   = var.min_worker_memory_gb

}

# ============================================================
# Module: BNK Orchestrator
# ============================================================
# Deploys BNK Orchestrator to the cluster using dynamic authentication
# 
# Key Changes from Previous Implementation:
# - ✅ No manual kubeconfig management
# - ✅ Uses dynamic Kubernetes/Helm providers with IBM Cloud credentials
# - ✅ Works in CI/CD without ibmcloud CLI tool
# - ✅ Terraform-native credential handling
# ============================================================

# ============================================================
# Module: Cert-Manager
# ============================================================
# Deploys cert-manager to handle certificate lifecycle management
# Must be deployed before flo since flo creates cert-manager resources

module "cert_manager" {
  source = "./modules/cert-manager"

  # Depends on cluster data source (works with both new and existing clusters)
  depends_on = [data.ibm_container_cluster_config.cluster_config]

  # Pass configured providers to the module
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }

  enabled = var.deploy_bnk

  namespace            = var.cert_manager_namespace
  chart_version        = var.cert_manager_version
  post_deployment_delay = 30
}

# ============================================================
# Module: FLO (F5 Lifecycle Operator)
# ============================================================

module "flo" {
  source = "./modules/flo"

  # Ensure cert-manager is deployed first
  # Also depend on cluster config (works with both new and existing clusters)
  depends_on = [module.cert_manager, data.ibm_container_cluster_config.cluster_config]

  providers = {
    kubernetes = kubernetes
    helm       = helm
    ibm        = ibm
  }

  enabled = var.deploy_bnk

  cert_manager_crd_ready = module.cert_manager.crd_ready

  far_service_account_key_path = var.far_service_account_key_path
  far_repo_url                 = var.far_repo_url

  # COS Bucket Configuration
  use_cos_bucket                = var.use_cos_bucket
  ibmcloud_api_key              = var.ibmcloud_api_key
  ibmcloud_cos_bucket_region    = var.ibmcloud_cos_bucket_region
  ibmcloud_resource_group       = var.resource_group
  ibmcloud_cos_instance_name    = var.ibmcloud_cos_instance_name
  ibmcloud_resources_cos_bucket = var.ibmcloud_resources_cos_bucket
  f5_cne_far_auth_file          = var.f5_cne_far_auth_file
  f5_cne_subscription_jwt_file  = var.f5_cne_subscription_jwt_file

  # F5 Manifest and FLO Configuration
  f5_bigip_k8s_manifest_version = var.f5_bigip_k8s_manifest_version
  flo_chart_version             = var.flo_chart_version
  flo_namespace                 = var.flo_namespace
  utils_namespace               = var.utils_namespace

  # JWT Token for licensing
  jwt_token = var.jwt_token

  # BIG-IP CIS Configuration
  bigip_username = var.bigip_username
  bigip_password = var.bigip_password
  bigip_url      = var.bigip_url

  # NAD Configuration
  nad_cni_type        = var.nad_cni_type
  nad_interface_name  = var.nad_interface_name
  nad_ipvlan_mode     = var.nad_ipvlan_mode

  # CNEInstance Configuration
  cneinstance_enabled             = var.cneinstance_enabled
  cneinstance_gateway_api         = var.cneinstance_gateway_api
  cneinstance_whole_cluster       = var.cneinstance_whole_cluster
  cneinstance_logging_subsystem   = var.cneinstance_logging_subsystem
  cneinstance_metric_subsystem    = var.cneinstance_metric_subsystem
  cneinstance_dynamic_routing     = var.cneinstance_dynamic_routing
  cneinstance_firewall_acl        = var.cneinstance_firewall_acl
  cneinstance_pseudocni           = var.cneinstance_pseudocni
  cneinstance_cloud_env           = var.cneinstance_cloud_env
  cneinstance_env_discovery       = var.cneinstance_env_discovery
  cneinstance_cloud_provider      = var.cneinstance_cloud_provider
  cneinstance_fluentbit           = var.cneinstance_fluentbit

  # Certificate Manager Configuration
  cert_manager_namespace = var.cert_manager_namespace
  cert_manager_version   = var.cert_manager_version
}

# ============================================================
# Module: CNEInstance
# ============================================================
# Deploys CNEInstance custom resource after FLO deployment 
# is fully completed (ensures FLO CRD is available)

module "cneinstance" {
  source = "./modules/cneinstance"

  depends_on = [module.flo]

  providers = {
    kubernetes = kubernetes
  }

  enabled = var.deploy_bnk && var.cneinstance_enabled

  flo_namespace         = var.flo_namespace
  utils_namespace       = var.utils_namespace

  f5_bigip_k8s_manifest_version = var.f5_bigip_k8s_manifest_version
  cneinstance_gateway_api       = var.cneinstance_gateway_api
  cneinstance_whole_cluster     = var.cneinstance_whole_cluster
  cneinstance_logging_subsystem = var.cneinstance_logging_subsystem
  cneinstance_metric_subsystem  = var.cneinstance_metric_subsystem
  cneinstance_deployment_size   = var.cneinstance_deployment_size
  cneinstance_dynamic_routing   = var.cneinstance_dynamic_routing
  cneinstance_firewall_acl      = var.cneinstance_firewall_acl
  cneinstance_pseudocni         = var.cneinstance_pseudocni
  cneinstance_env_discovery     = var.cneinstance_env_discovery
  cneinstance_cloud_env         = var.cneinstance_cloud_env
  cneinstance_cloud_provider    = var.cneinstance_cloud_provider
  cneinstance_vpc_name          = var.cneinstance_vpc_name
  cneinstance_cloud_region      = var.cneinstance_cloud_region
  cneinstance_ibm_trusted_profile_id = var.cneinstance_ibm_trusted_profile_id
  cneinstance_gslb_datacenter_name   = var.cneinstance_gslb_datacenter_name
  cneinstance_fluentbit         = var.cneinstance_fluentbit
  cneinstance_network_attachments = module.flo.cneinstance_network_attachments
  
  cluster_issuer_name = module.flo.cluster_issuer_name
  far_repo_url        = var.far_repo_url

  flo_deployment_dependency = module.flo
}

# ============================================================
# Module: License
# ============================================================
# Deploys F5 BNK License CR after CNEInstance deployment
# ensures the License CRD is available before applying

module "license" {
  source = "./modules/license"

  depends_on = [module.cneinstance]

  providers = {
    kubernetes = kubernetes
  }

  enabled = var.deploy_bnk && var.cneinstance_enabled

  utils_namespace = var.utils_namespace
  jwt_token       = var.use_cos_bucket ? module.flo.cos_jwt_token : var.jwt_token
  license_mode    = var.license_mode

  cneinstance_dependency = module.cneinstance
}
