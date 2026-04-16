# ============================================================
# Root Terraform Variables
# ============================================================

# IBM Cloud Configuration
variable "ibmcloud_api_key" {
  description = "IBM Cloud API Key"
  type        = string
  sensitive   = true
}

variable "cluster_region" {
  description = "IBM Cloud region for cluster resources"
  type        = string
  default     = "jp-tok"
}

variable "resource_group" {
  description = "Resource group name"
  type        = string
  default     = "default"
}

# Feature Flags
variable "create_cluster" {
  description = "Create OpenShift cluster"
  type        = bool
  default     = true
}

variable "create_client_vpc" {
  description = "Create client VPC"
  type        = bool
  default     = true
}

variable "create_jumphost" {
  description = "Create jumphost in client VPC"
  type        = bool
  default     = true
}

variable "create_transit_gateway" {
  description = "Create transit gateway"
  type        = bool
  default     = true
}

variable "create_cos_instance" {
  description = "Create Cloud Object Storage instance"
  type        = bool
  default     = true
}

# VPC Configuration
variable "cluster_vpc_name" {
  description = "Name of the cluster VPC"
  type        = string
  default     = "tf-cluster-vpc"
}

# Zone Configuration
# variable "zone1_prefix_cidr" {
#   description = "CIDR for zone 1 address prefix"
#   type        = string
#   default     = "10.155.15.0/24"
# }

# variable "zone2_prefix_cidr" {
#   description = "CIDR for zone 2 address prefix"
#   type        = string
#   default     = "10.156.16.0/24"
# }

# variable "zone3_prefix_cidr" {
#   description = "CIDR for zone 3 address prefix"
#   type        = string
#   default     = "10.157.17.0/24"
# }

# variable "zone1_virtual_ip" {
#   description = "Virtual IP for zone 1 load balancer member"
#   type        = string
#   default     = "10.155.15.101"
# }

# variable "zone2_virtual_ip" {
#   description = "Virtual IP for zone 2 load balancer member"
#   type        = string
#   default     = "10.156.16.101"
# }

# variable "zone3_virtual_ip" {
#   description = "Virtual IP for zone 3 load balancer member"
#   type        = string
#   default     = "10.157.17.101"
# }

# Client VPC Configuration
variable "client_vpc_name" {
  description = "Name of the client VPC"
  type        = string
  default     = "tf-client-vpc"
}

variable "client_vpc_region" {
  description = "IBM Cloud region for client VPC"
  type        = string
  default     = "eu-gb"
}

variable "client_jumphost_name" {
  description = "Name of the jumphost instance"
  type        = string
  default     = "tf-client-jumphost"
}

variable "ssh_key_name" {
  description = "SSH key name for jumphost"
  type        = string
  default     = "test-jh"
}

# Transit Gateway
variable "transit_gateway_name" {
  description = "Name of the transit gateway"
  type        = string
  default     = "tf-tgw"
}

# Cloud Object Storage
variable "cos_instance_name" {
  description = "Name of the COS instance"
  type        = string
  default     = "tf-cos-instance"
}

# OpenShift Cluster Configuration
variable "openshift_cluster_name" {
  description = "Name of the OpenShift cluster"
  type        = string
  default     = "tf-openshift-cluster"
}

variable "workers_per_zone" {
  description = "Number of worker nodes per zone"
  type        = number
  default     = 1
}

variable "min_worker_vcpu_count" {
  description = "Minimum vCPU count for worker nodes"
  type        = number
  default     = 16
}

variable "min_worker_memory_gb" {
  description = "Minimum memory in GB for worker nodes"
  type        = number
  default     = 64
}

# Load Balancer Configuration
# variable "enable_load_balancer" {
#   description = "Enable application load balancer"
#   type        = bool
#   default     = false
# }

# variable "lb_name" {
#   description = "Name of the load balancer"
#   type        = string
#   default     = "tf-lb"
# }

# Existing Cluster Configuration (for using existing clusters)
variable "cluster_id_existing" {
  description = "ID or name of existing OpenShift cluster (used when create_cluster=false)"
  type        = string
  default     = ""
}

# ============================================================
# BNK Orchestrator Module Variables
# ============================================================

variable "deploy_bnk" {
  description = "Whether to deploy the F5 BNK Orchestrator module"
  type        = bool
  default     = false
}

variable "far_service_account_key_path" {
  description = "Path to FAR service account key JSON file"
  type        = string
  default     = "/home/dev/dev_pull_64.json"
}

variable "far_repo_url" {
  description = "FAR Repository URL for docker and helm registry"
  type        = string
  default     = "repo.f5.com"
}

# COS Bucket Configuration (Optional - fetch FAR auth key and JWT from COS)
variable "use_cos_bucket" {
  description = "Fetch FAR auth key and JWT from IBM Cloud Object Storage instead of local files"
  type        = bool
  default     = true
}

variable "ibmcloud_cos_bucket_region" {
  description = "IBM Cloud region where the COS bucket is located"
  type        = string
  default     = "us-south"
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

variable "f5_bigip_k8s_manifest_version" {
  description = "Version of f5-bigip-k8s-manifest chart"
  type        = string
  default     = ""
}

variable "flo_chart_version" {
  description = "Version of f5-lifecycle-operator chart to install"
  type        = string
  default     = ""
}

variable "flo_namespace" {
  description = "Namespace for F5 Lifecycle Operator"
  type        = string
  default     = "f5-bnk"
}

variable "utils_namespace" {
  description = "Namespace for F5 utility components (shared infrastructure)"
  type        = string
  default     = "f5-utils"
}

variable "jwt_token" {
  description = "JWT token for F5 license authentication"
  type        = string
  default     = ""
  sensitive   = true
}

variable "bigip_username" {
  description = "BIG-IP username for CIS controller login"
  type        = string
  default     = "admin"
}

variable "bigip_password" {
  description = "BIG-IP password for CIS controller login"
  type        = string
  default     = ""
  sensitive   = true
}

variable "bigip_url" {
  description = "BIG-IP URL for CIS controller login"
  type        = string
  default     = ""
}

variable "license_mode" {
  description = "License operation mode (connected or disconnected)"
  type        = string
  default     = "connected"
}

variable "cneinstance_enabled" {
  description = "Enable CNEInstance deployment"
  type        = bool
  default     = true
}

variable "cneinstance_logging_subsystem" {
  description = "Logging subsystem for CNEInstance"
  type        = string
  default     = ""
}


variable "cneinstance_gateway_api" {
  description = "Enable Gateway API support for CNEInstance"
  type        = bool
  default     = true
}

variable "cneinstance_whole_cluster" {
  description = "Apply CNEInstance to whole cluster"
  type        = bool
  default     = true
}

variable "cneinstance_metric_subsystem" {
  description = "Enable metrics subsystem for CNEInstance"
  type        = bool
  default     = false
}

variable "cneinstance_dynamic_routing" {
  description = "Enable dynamic routing for CNEInstance"
  type        = bool
  default     = false
}

variable "cneinstance_firewall_acl" {
  description = "Enable firewall ACL for CNEInstance"
  type        = bool
  default     = false
}

variable "cneinstance_pseudocni" {
  description = "Enable pseudo-CNI mode for CNEInstance"
  type        = bool
  default     = true
}

variable "cneinstance_cloud_env" {
  description = "Enable cloud environment for CNEInstance"
  type        = bool
  default     = true
}

variable "cneinstance_env_discovery" {
  description = "Enable environment discovery for CNEInstance"
  type        = bool
  default     = false
}

variable "cneinstance_cloud_provider" {
  description = "Cloud provider for CNEInstance (aws, azure, gcp, ibm)"
  type        = string
  default     = "ibm"
}

variable "cneinstance_vpc_name" {
  description = "VPC name for CNEInstance cloud environment"
  type        = string
  default     = ""
}

variable "cneinstance_cloud_region" {
  description = "Cloud region for CNEInstance environment"
  type        = string
  default     = ""
}

variable "cneinstance_ibm_trusted_profile_id" {
  description = "IBM Trusted Profile ID for CNEInstance authentication"
  type        = string
  default     = ""
}

variable "cneinstance_gslb_datacenter_name" {
  description = "GSLB datacenter name for CNEInstance"
  type        = string
  default     = ""
}

variable "cneinstance_fluentbit" {
  description = "Enable Fluentbit logging for CNEInstance"
  type        = bool
  default     = false
}

variable "cneinstance_deployment_size" {
  description = "Deployment size for CNEInstance (Small, Medium, Large)"
  type        = string
  default     = "Small"
}

variable "nad_cni_type" {
  description = "CNI type for NetworkAttachmentDefinition (ipvlan or host-device)"
  type        = string
  default     = "ipvlan"
}

variable "nad_interface_name" {
  description = "Network interface name for NAD"
  type        = string
  default     = "ens3"
}

variable "nad_ipvlan_mode" {
  description = "IPVLAN mode (l2 or l3)"
  type        = string
  default     = "l2"
}

variable "cert_manager_namespace" {
  description = "Kubernetes namespace for cert-manager"
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_version" {
  description = "cert-manager Helm chart version"
  type        = string
  default     = "v1.16.1"
}