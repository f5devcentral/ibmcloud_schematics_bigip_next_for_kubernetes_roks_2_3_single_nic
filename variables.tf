# ============================================================
# Root Terraform Variables
# ============================================================


# ============================================================
# IBM Cloud Variables
# ============================================================

variable "ibmcloud_api_key" {
  description = "IBM Cloud API Key - used by cluster, flo modules"
  type        = string
  sensitive   = true
}

variable "ibmcloud_cluster_region" {
  description = "IBM Cloud region for cluster resources - used by cluster module"
  type        = string
  default     = "jp-tok"
}

variable "ibmcloud_resource_group" {
  description = "IBM Cloud Resource Group name - used by cluster, flo modules"
  type        = string
  default     = "default"
}

# ============================================================
# Feature Flags
# ============================================================

variable "create_cluster" {
  description = "Create OpenShift cluster - used by cluster module"
  type        = bool
  default     = true
}

variable "create_transit_gateway" {
  description = "Create transit gateway - used by cluster module"
  type        = bool
  default     = true
}

variable "create_cos_instance" {
  description = "Create Cloud Object Storage instance for IBM ROKs registry - used by cluster module"
  type        = bool
  default     = true
}

variable "create_client_vpc" {
  description = "Create client VPC - used by cluster module"
  type        = bool
  default     = true
}

variable "create_jumphost" {
  description = "Create jumphost in client VPC - used by cluster module"
  type        = bool
  default     = true
}

variable "deploy_bnk" {
  description = "Deploy the F5 BNK Orchestrator module - used by cert-manager, flo, cneinstance, license modules"
  type        = bool
  default     = true
}

# ============================================================
# Cluster Variables
# ============================================================

variable "cluster_vpc_name" {
  description = "Name of the cluster VPC - used by cluster module"
  type        = string
  default     = "tf-cluster-vpc"
}

variable "transit_gateway_name" {
  description = "Name of the transit gateway - used by cluster module"
  type        = string
  default     = "tf-tgw"
}

variable "cos_instance_name" {
  description = "Name of the COS instance for IBM ROKs registry - used by cluster module"
  type        = string
  default     = "tf-cos-instance"
}

variable "openshift_cluster_name" {
  description = "Name of the OpenShift cluster - used by cluster module"
  type        = string
  default     = "tf-openshift-cluster"
}

variable "openshift_cluster_version" {
  description = "OpenShift cluster version (e.g. 4.18). If empty, the latest available version is used."
  type        = string
  default     = "4.18"
}

variable "workers_per_zone" {
  description = "Number of worker nodes per zone - used by cluster module"
  type        = number
  default     = 1
}

variable "min_worker_vcpu_count" {
  description = "Minimum vCPU count for worker nodes - used by cluster module"
  type        = number
  default     = 16
}

variable "min_worker_memory_gb" {
  description = "Minimum memory in GB for worker nodes - used by cluster module"
  type        = number
  default     = 64
}

# Existing Cluster Configuration (for using existing clusters)
variable "cluster_id_existing" {
  description = "ID or name of existing OpenShift cluster (used when create_cluster=false) - used by providers"
  type        = string
  default     = ""
}

# ============================================================
# Test Client Variables
# ============================================================

# TO DO - Refactor module to break out test client into its own module

variable "client_vpc_name" {
  description = "Name of the client VPC - used by cluster module"
  type        = string
  default     = "tf-client-vpc"
}

variable "client_vpc_region" {
  description = "IBM Cloud region for client VPC - used by cluster module"
  type        = string
  default     = "eu-gb"
}

variable "client_jumphost_name" {
  description = "Name of the jumphost instance - used by cluster module"
  type        = string
  default     = "tf-client-jumphost"
}

variable "ssh_key_name" {
  description = "SSH key name for jumphost - used by cluster module"
  type        = string
  default     = "test-jh"
}

# ============================================================
# BNK Orchestrator Module Variables
# ============================================================

variable "far_service_account_key_path" {
  description = "Path to FAR service account key JSON file - used by flo module"
  type        = string
  default     = "/home/dev/dev_pull_64.json"
}

variable "far_repo_url" {
  description = "FAR Repository URL for docker and helm registry - used by flo, cneinstance modules"
  type        = string
  default     = "repo.f5.com"
}

# COS Bucket Configuration (Optional - fetch FAR auth key and JWT from COS)
variable "use_cos_bucket" {
  description = "Fetch FAR auth key and JWT from IBM Cloud Object Storage instead of local files - used by flo, license modules"
  type        = bool
  default     = true
}

variable "ibmcloud_cos_bucket_region" {
  description = "IBM Cloud region where the COS bucket is located - used by flo module"
  type        = string
  default     = "us-south"
}

variable "ibmcloud_cos_instance_name" {
  description = "IBM Cloud COS instance name - used by flo module"
  type        = string
  default     = "bnk-orchestration"
}

variable "ibmcloud_resources_cos_bucket" {
  description = "IBM Cloud COS bucket for file resources - used by flo module"
  type        = string
  default     = "bnk-schematics-resources"
}

variable "f5_cne_far_auth_file" {
  description = "FAR auth key filename in COS bucket (.tgz) - used by flo module"
  type        = string
  default     = "f5-far-auth-key.tgz"
}

variable "f5_cne_subscription_jwt_file" {
  description = "Subscription JWT filename in COS bucket - used by flo module"
  type        = string
  default     = "trial.jwt"
}

variable "f5_bigip_k8s_manifest_version" {
  description = "Version of f5-bigip-k8s-manifest chart - used by flo, cneinstance modules"
  type        = string
  default     = "2.3.0-bnpp-ehf-2-3.2598.3-0.0.17"
}

variable "flo_namespace" {
  description = "Namespace for F5 Lifecycle Operator - used by flo, cneinstance modules"
  type        = string
  default     = "f5-bnk"
}

variable "utils_namespace" {
  description = "Namespace for F5 utility components (shared infrastructure) - used by flo, cneinstance, license modules"
  type        = string
  default     = "f5-utils"
}

variable "jwt_token" {
  description = "JWT token for F5 license authentication (if not retrieved from IBM COS) - used by flo, license modules"
  type        = string
  default     = ""
  sensitive   = true
}

variable "bigip_username" {
  description = "BIG-IP username for CIS controller login - used by flo module"
  type        = string
  default     = "admin"
}

variable "bigip_password" {
  description = "BIG-IP password for CIS controller login - used by flo module"
  type        = string
  default     = ""
  sensitive   = true
}

variable "bigip_url" {
  description = "BIG-IP URL for CIS controller login - used by flo module"
  type        = string
  default     = ""
}

variable "license_mode" {
  description = "License operation mode (connected or disconnected) - used by license module"
  type        = string
  default     = "connected"
}

variable "cneinstance_enabled" {
  description = "Enable CNEInstance deployment - used by cneinstance, license modules"
  type        = bool
  default     = true
}

variable "cneinstance_logging_subsystem" {
  description = "Enable logging subsystem - used by flo, cneinstance modules"
  type        = bool
  default     = false
}

variable "cneinstance_gateway_api" {
  description = "Enable Gateway API support for CNEInstance - used by flo, cneinstance modules"
  type        = bool
  default     = true
}

variable "cneinstance_whole_cluster" {
  description = "Apply CNEInstance to whole cluster - used by flo, cneinstance modules"
  type        = bool
  default     = true
}

variable "cneinstance_metric_subsystem" {
  description = "Enable metrics subsystem for CNEInstance - used by flo, cneinstance modules"
  type        = bool
  default     = false
}

variable "cneinstance_dynamic_routing" {
  description = "Enable dynamic routing for CNEInstance - used by flo, cneinstance modules"
  type        = bool
  default     = false
}

variable "cneinstance_firewall_acl" {
  description = "Enable firewall ACL for CNEInstance - used by flo, cneinstance modules"
  type        = bool
  default     = false
}

variable "cneinstance_pseudocni" {
  description = "Enable pseudo-CNI mode for CNEInstance - used by flo, cneinstance modules"
  type        = bool
  default     = true
}

variable "cneinstance_cloud_env" {
  description = "Enable cloud environment for CNEInstance - used by flo, cneinstance modules"
  type        = bool
  default     = true
}

variable "cneinstance_env_discovery" {
  description = "Enable environment discovery for CNEInstance - used by flo, cneinstance modules"
  type        = bool
  default     = false
}

variable "cneinstance_cloud_provider" {
  description = "Cloud provider for CNEInstance (aws, azure, gcp, ibm) - used by flo, cneinstance modules"
  type        = string
  default     = "ibm"
}

variable "cneinstance_vpc_name" {
  description = "VPC name for CNEInstance cloud environment - used by cneinstance module"
  type        = string
  default     = "tf-cluster-vpc"
}

variable "cneinstance_cloud_region" {
  description = "Cloud region for CNEInstance environment - used by cneinstance module"
  type        = string
  default     = "jp-tok"
}

variable "cneinstance_ibm_trusted_profile_id" {
  description = "IBM Trusted Profile ID for CNEInstance authentication - used by cneinstance module"
  type        = string
  default     = ""
}

variable "cneinstance_gslb_datacenter_name" {
  description = "GSLB datacenter name for CNEInstance (optional for deployment) - used by cneinstance module"
  type        = string
  default     = ""
}

variable "cneinstance_fluentbit" {
  description = "Enable Fluentbit logging for CNEInstance - used by flo, cneinstance modules"
  type        = bool
  default     = false
}

variable "cneinstance_deployment_size" {
  description = "Deployment size for CNEInstance (Small, Medium, Large) - used by cneinstance module"
  type        = string
  default     = "Small"
}

variable "nad_cni_type" {
  description = "CNI type for NetworkAttachmentDefinition (ipvlan or host-device) - used by flo module"
  type        = string
  default     = "ipvlan"
}

variable "nad_interface_name" {
  description = "Network interface name for NAD - used by flo module"
  type        = string
  default     = "ens3"
}

variable "nad_ipvlan_mode" {
  description = "IPVLAN mode (l2 or l3) - used by flo module"
  type        = string
  default     = "l2"
}

variable "cert_manager_namespace" {
  description = "Kubernetes namespace for cert-manager - used by cert-manager, flo modules"
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_version" {
  description = "cert-manager Helm chart version - used by cert-manager, flo modules"
  type        = string
  default     = "v1.17.3"
}
