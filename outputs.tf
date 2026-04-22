# ============================================================
# Root Terraform Outputs
# ============================================================

# Cluster Module Outputs
output "cluster_id" {
  description = "ID of the OpenShift cluster"
  value       = module.cluster.cluster_id
}

output "cluster_name" {
  description = "Name of the OpenShift cluster"
  value       = module.cluster.cluster_name
}

output "openshift_cluster_id" {
  description = "ID of the OpenShift cluster"
  value       = module.cluster.openshift_cluster_id
}

output "openshift_cluster_name" {
  description = "Name of the OpenShift cluster"
  value       = module.cluster.openshift_cluster_name
}

output "openshift_cluster_public_endpoint" {
  description = "Public endpoint URL for the OpenShift cluster"
  value       = module.cluster.openshift_cluster_public_endpoint
}

output "openshift_cluster_ingress_hostname" {
  description = "Ingress hostname for the OpenShift cluster"
  value       = module.cluster.openshift_cluster_ingress_hostname
}

output "kubeconfig_file_path" {
  description = "Path to the kubeconfig file for the OpenShift cluster"
  value       = module.cluster.kubeconfig_file_path
}

output "cluster_vpc_id" {
  description = "ID of the cluster VPC"
  value       = module.cluster.cluster_vpc_id
}

output "cluster_vpc_name" {
  description = "Name of the cluster VPC"
  value       = module.cluster.cluster_vpc_name
}

output "cluster_vpc_crn" {
  description = "CRN of the cluster VPC"
  value       = module.cluster.cluster_vpc_crn
}

output "openshift_cluster_crn" {
  description = "CRN of the OpenShift cluster"
  value       = module.cluster.openshift_cluster_crn
}

output "transit_gateway_id" {
  description = "ID of the transit gateway"
  value       = module.cluster.transit_gateway_id
}

# Worker IPs
output "openshift_worker_zone1_ip" {
  description = "IP address of the worker node in zone 1"
  value       = module.cluster.openshift_worker_zone1_ip
}

output "openshift_worker_zone2_ip" {
  description = "IP address of the worker node in zone 2"
  value       = module.cluster.openshift_worker_zone2_ip
}

output "openshift_worker_zone3_ip" {
  description = "IP address of the worker node in zone 3"
  value       = module.cluster.openshift_worker_zone3_ip
}

# Additional Cluster Module Outputs
output "openshift_version_used" {
  description = "OpenShift version used for cluster"
  value       = module.cluster.openshift_version_used
}

output "available_openshift_versions" {
  description = "All available OpenShift versions in the cluster region"
  value       = module.cluster.available_openshift_versions
}

# Client VPC Outputs
output "client_vpc_id" {
  description = "ID of the client VPC"
  value       = module.cluster.client_vpc_id
}

output "client_vpc_name" {
  description = "Name of the client VPC"
  value       = module.cluster.client_vpc_name
}

# Jumphost Outputs
output "client_jumphost_id" {
  description = "ID of the client jumphost"
  value       = module.cluster.client_jumphost_id
}

output "client_jumphost_private_ip" {
  description = "Private IP of the client jumphost"
  value       = module.cluster.client_jumphost_private_ip
}

output "client_jumphost_public_ip" {
  description = "Public IP of the client jumphost"
  value       = module.cluster.client_jumphost_public_ip
}

output "client_jumphost_ssh_command" {
  description = "SSH command to connect to the client jumphost"
  value       = module.cluster.client_jumphost_ssh_command
}

# Cluster Status
output "openshift_cluster_state" {
  description = "State of the OpenShift cluster"
  value       = module.cluster.openshift_cluster_state
}

output "openshift_cluster_private_endpoint" {
  description = "Private endpoint URL for the OpenShift cluster"
  value       = module.cluster.openshift_cluster_private_endpoint
}

# Transit Gateway Details
output "transit_gateway_name" {
  description = "Name of the transit gateway"
  value       = module.cluster.transit_gateway_name
}

output "transit_gateway_crn" {
  description = "CRN of the transit gateway"
  value       = module.cluster.transit_gateway_crn
}

output "transit_gateway_location" {
  description = "Location of the transit gateway"
  value       = module.cluster.transit_gateway_location
}

output "transit_gateway_global_routing" {
  description = "Global routing status of the transit gateway"
  value       = module.cluster.transit_gateway_global_routing
}

