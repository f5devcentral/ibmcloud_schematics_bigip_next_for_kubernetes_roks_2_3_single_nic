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
# Transit Gateway Variables
# ============================================================

variable "transit_gateway_name" {
  description = "Name of the transit gateway - used by cluster module"
  type        = string
  default     = "tf-tgw"
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

variable "far_repo_url" {
  description = "FAR Repository URL for docker and helm registry - used by flo, cneinstance modules"
  type        = string
  default     = "repo.f5.com"
}

variable "license_mode" {
  description = "License operation mode (connected or disconnected) - used by license module"
  type        = string
  default     = "connected"
}

# Version to install
variable "f5_bigip_k8s_manifest_version" {
  description = "Version of f5-bigip-k8s-manifest chart - used by flo, cneinstance modules"
  type        = string
  default     = "2.3.0-bnpp-ehf-2-3.2598.3-0.0.17"
}

# IBM COS FAR and JWT
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

# Local file FAR and JWT

variable "jwt_token" {
  description = "JWT token for F5 license authentication (if not retrieved from IBM COS) - used by flo, license modules"
  type        = string
  default     = ""
  sensitive   = true
}

# Community Cert-Manager

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

# Where it install the F5 Operator

variable "flo_namespace" {
  description = "Namespace for F5 Lifecycle Operator - used by flo, cneinstance modules"
  type        = string
  default     = "f5-bnk"
}

# Where to install the F5 control plane utilities

variable "utils_namespace" {
  description = "Namespace for F5 utility components (shared infrastructure) - used by flo, cneinstance, license modules"
  type        = string
  default     = "f5-utils"
}

# CIS TMOS Integration

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

# Deploy CNE Instance as a Gateway Provider

variable "cneinstance_enabled" {
  description = "Enable CNEInstance deployment - used by cneinstance, license modules"
  type        = bool
  default     = true
}

variable "cneinstance_gslb_datacenter_name" {
  description = "GSLB datacenter name for CNEInstance (optional for deployment) - used by cneinstance module"
  type        = string
  default     = ""
}

variable "cneinstance_deployment_size" {
  description = "Deployment size for CNEInstance (Small, Medium, Large) - used by cneinstance module"
  type        = string
  default     = "Small"
}

