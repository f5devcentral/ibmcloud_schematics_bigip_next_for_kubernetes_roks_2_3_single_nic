variable "enabled" {
  description = "Enable or disable the BNK orchestrator module deployment"
  type        = bool
  default     = false
}

variable "cert_manager_crd_ready" {
  description = "Dependency indicator from cert-manager module (ensures cert-manager is deployed before this module)"
  type        = string
  default     = null
}

variable "far_service_account_key_path" {
  description = "Path to FAR service account key JSON file (e.g., dev_pull_64.json)"
  type        = string
  default     = "/home/dev/dev_pull_64.json"
}

variable "far_repo_url" {
  description = "FAR Repository URL for docker and helm registry"
  type        = string
  default     = "repo.f5.com"
}

variable "cert_manager_namespace" {
  description = "Namespace for cert-manager installation"
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_version" {
  description = "Version of cert-manager to install"
  type        = string
  default     = "v1.16.1"
}

# F5 BIG-IP K8s Manifest Variables
variable "f5_bigip_k8s_manifest_version" {
  description = "Version of f5-bigip-k8s-manifest chart (FLO version will be extracted from this)"
  type        = string
}

variable "manifest_download_dir" {
  description = "Directory to download and extract manifest chart"
  type        = string
  default     = "/tmp/f5-manifest"
}

# F5 Lifecycle Operator (FLO) Variables
variable "bigip_username" {
  description = "BIG-IP username for CIS controller login"
  type        = string
  default     = "admin"
}

variable "bigip_password" {
  description = "BIG-IP password for CIS controller login"
  type        = string
  sensitive   = true
}

variable "bigip_url" {
  description = "BIG-IP URL for CIS controller login"
  type        = string
  default     = ""
}

variable "flo_namespace" {
  description = "Namespace for f5-lifecycle-operator installation"
  type        = string
  default     = "f5-bnk"
}

variable "utils_namespace" {
  description = "Namespace for F5 Utilities"
  type        = string
  default     = "f5-utils"
}

variable "jwt_token" {
  description = "JWT token for license authentication"
  type        = string
  sensitive   = true
}

variable "cluster_issuer_name" {
  description = "Name of the cluster issuer for certificates"
  type        = string
  default     = "sample-issuer"
}

# NetworkAttachmentDefinition (NAD) Variables
variable "nad_cni_type" {
  description = "CNI type for NAD (host-device or ipvlan)"
  type        = string
  default     = "ipvlan"
  validation {
    condition     = contains(["host-device", "ipvlan"], var.nad_cni_type)
    error_message = "CNI type must be either 'host-device' or 'ipvlan'."
  }
}

variable "nad_interface_name" {
  description = "Network interface name for NAD (e.g., ens7, eth1)"
  type        = string
  default     = "ens3"
}

variable "nad_ipvlan_mode" {
  description = "IPVLAN mode (l2 or l3) - only used when nad_cni_type is ipvlan"
  type        = string
  default     = "l2"
  validation {
    condition     = contains(["l2", "l3"], var.nad_ipvlan_mode)
    error_message = "IPVLAN mode must be either 'l2' or 'l3'."
  }
}

variable "nad_ipvlan_address" {
  description = "Static IP address with CIDR for IPVLAN (e.g., 10.10.1.1/24) - only used when nad_cni_type is ipvlan"
  type        = string
  default     = "10.10.1.1/24"
}

# CNEInstance Variables
variable "cneinstance_enabled" {
  description = "Enable CNEInstance CR creation"
  type        = bool
  default     = true
}

variable "cneinstance_gateway_api" {
  description = "Enable Gateway API support"
  type        = bool
  default     = true
}

variable "cneinstance_whole_cluster" {
  description = "Enable whole cluster mode"
  type        = bool
  default     = true
}

variable "cneinstance_logging_subsystem" {
  description = "Enable logging subsystem"
  type        = bool
  default     = true
}

variable "cneinstance_metric_subsystem" {
  description = "Enable metric subsystem"
  type        = bool
  default     = true
}

variable "cneinstance_dynamic_routing" {
  description = "Enable dynamic routing"
  type        = bool
  default     = false
}

variable "cneinstance_firewall_acl" {
  description = "Enable firewall ACL (AFM)"
  type        = bool
  default     = false
}

variable "cneinstance_pseudocni" {
  description = "Enable PseudoCNI"
  type        = bool
  default     = true
}

variable "cneinstance_cloud_provider" {
  description = "Cloud provider (aws, azure, gcp, generic)"
  type        = string
  default     = "ibm"
}

variable "cneinstance_fluentbit" {
  description = "Enable Fluentbit for logging"
  type        = bool
  default     = true
}

variable "cneinstance_deployment_size" {
  description = "Deployment size (Small, Medium, Large)"
  type        = string
  default     = "Small"
}

variable "cneinstance_cloud_env" {
  description = "Enable cloud environment mode"
  type        = bool
  default     = true
}

variable "cneinstance_env_discovery" {
  description = "Enable environment discovery in CNEInstance"
  type        = bool
  default     = false
}

# ==============================================================================
# COS Bucket Configuration (Optional - fetch FAR auth key and JWT from COS)
# ==============================================================================

variable "use_cos_bucket" {
  description = "Fetch FAR auth key and JWT from IBM Cloud Object Storage instead of local files"
  type        = bool
  default     = true
}

variable "ibmcloud_api_key" {
  description = "IBM Cloud API Key (required when use_cos_bucket = true)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ibmcloud_cos_bucket_region" {
  description = "IBM Cloud region where the COS bucket is located (required when use_cos_bucket = true)"
  type        = string
  default     = "us-south"
}

variable "ibmcloud_resource_group" {
  description = "IBM Cloud resource group name (required when use_cos_bucket = true)"
  type        = string
  default     = "default"
}

variable "ibmcloud_cos_instance_name" {
  description = "IBM Cloud COS instance name"
  type        = string
  default     = "bnk-orchestration"
}

variable "ibmcloud_resources_cos_bucket" {
  description = "IBM Cloud COS bucket for file resources"
  type        = string
  default     = "bnk-schematics-resources"
}

variable "f5_cne_far_auth_file" {
  description = "FAR auth key filename in COS bucket (.tgz)"
  type        = string
  default     = "f5-far-auth-key.tgz"
}

variable "f5_cne_subscription_jwt_file" {
  description = "Subscription JWT filename in COS bucket"
  type        = string
  default     = "trial.jwt"
}
