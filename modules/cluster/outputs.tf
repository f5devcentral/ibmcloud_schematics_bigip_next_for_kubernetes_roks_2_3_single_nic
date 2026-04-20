output "cluster_vpc_id" {
  description = "ID of the cluster VPC"
  value       = local.cluster_vpc_id
}

output "cluster_vpc_name" {
  description = "Name of the cluster VPC"
  value       = var.use_existing_cluster_vpc ? data.ibm_is_vpc.existing_cluster_vpc[0].name : ibm_is_vpc.cluster_vpc[0].name
}

output "openshift_version_used" {
  description = "OpenShift version used for cluster (auto-detected if not specified)"
  value       = local.openshift_version
}

output "available_openshift_versions" {
  description = "All available OpenShift versions in the cluster region"
  value       = local.available_openshift_versions
}

output "cluster_vpc_crn" {
  description = "CRN of the cluster VPC"
  value       = local.cluster_vpc_crn
}

# Client VPC and Jumphost Outputs (Sydney)
output "client_vpc_id" {
  description = "ID of the client VPC in Sydney"
  value       = var.create_client_vpc ? local.client_vpc_id : "Client VPC not created"
}

output "client_vpc_name" {
  description = "Name of the client VPC"
  value = var.create_client_vpc ? (
    var.use_existing_client_vpc ? data.ibm_is_vpc.existing_client_vpc[0].name : ibm_is_vpc.client_vpc[0].name
  ) : "Client VPC not created"
}

output "client_jumphost_id" {
  description = "ID of the client jumphost instance in Sydney"
  value       = var.create_client_vpc && var.create_jumphost ? ibm_is_instance.client_jumphost[0].id : "Jumphost not created"
}

output "client_jumphost_private_ip" {
  description = "Private IP address of the client jumphost"
  value       = var.create_client_vpc && var.create_jumphost ? ibm_is_instance.client_jumphost[0].primary_network_interface[0].primary_ip[0].address : "Jumphost not created"
}

output "client_jumphost_public_ip" {
  description = "Public IP address of the client jumphost in Sydney"
  value       = var.create_client_vpc && var.create_jumphost ? ibm_is_floating_ip.client_jumphost_fip[0].address : "Jumphost not created"
}

output "client_jumphost_ssh_command" {
  description = "SSH command to connect to client jumphost"
  value       = var.create_client_vpc && var.create_jumphost ? "ssh -i ${var.ssh_key_name} ubuntu@${ibm_is_floating_ip.client_jumphost_fip[0].address}" : "Jumphost not created"
}

# OpenShift Cluster Outputs
output "openshift_cluster_id" {
  description = "ID of the OpenShift cluster"
  value       = var.create_cluster ? ibm_container_vpc_cluster.openshift_cluster[0].id : "Cluster not created"
}

output "openshift_cluster_name" {
  description = "Name of the OpenShift cluster"
  value       = var.create_cluster ? ibm_container_vpc_cluster.openshift_cluster[0].name : "Cluster not created"
}

output "openshift_cluster_state" {
  description = "State of the OpenShift cluster"
  value       = var.create_cluster ? data.ibm_container_vpc_cluster.cluster_info[0].state : "Cluster not created"
}

output "openshift_cluster_ingress_hostname" {
  description = "Ingress hostname for the OpenShift cluster"
  value       = var.create_cluster ? ibm_container_vpc_cluster.openshift_cluster[0].ingress_hostname : "Cluster not created"
}

output "openshift_cluster_public_endpoint" {
  description = "Public service endpoint URL"
  value       = var.create_cluster ? ibm_container_vpc_cluster.openshift_cluster[0].public_service_endpoint_url : "Cluster not created"
}

output "openshift_cluster_private_endpoint" {
  description = "Private service endpoint URL"
  value       = var.create_cluster ? ibm_container_vpc_cluster.openshift_cluster[0].private_service_endpoint_url : "Cluster not created"
}

output "openshift_worker_zone1_ip" {
  description = "IP address of zone 1 worker node"
  value       = var.create_cluster ? local.zone1_worker_ip : "Cluster not created"
}

output "openshift_worker_zone2_ip" {
  description = "IP address of zone 2 worker node"
  value       = var.create_cluster ? local.zone2_worker_ip : "Cluster not created"
}

output "openshift_worker_zone3_ip" {
  description = "IP address of zone 3 worker node"
  value       = var.create_cluster ? local.zone3_worker_ip : "Cluster not created"
}

# Transit Gateway Outputs
output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = var.create_transit_gateway ? ibm_tg_gateway.transit_gateway[0].id : "Transit Gateway not created"
}

output "transit_gateway_name" {
  description = "Name of the Transit Gateway"
  value       = var.create_transit_gateway ? ibm_tg_gateway.transit_gateway[0].name : "Transit Gateway not created"
}

output "transit_gateway_crn" {
  description = "CRN of the Transit Gateway"
  value       = var.create_transit_gateway ? ibm_tg_gateway.transit_gateway[0].crn : "Transit Gateway not created"
}

output "transit_gateway_location" {
  description = "Location of the Transit Gateway"
  value       = var.create_transit_gateway ? ibm_tg_gateway.transit_gateway[0].location : "Transit Gateway not created"
}

output "transit_gateway_global_routing" {
  description = "Global routing status"
  value       = var.create_transit_gateway ? ibm_tg_gateway.transit_gateway[0].global : false
}

output "transit_gateway_connections" {
  description = "Transit Gateway connection summary"
  value = var.create_transit_gateway ? {
    cluster_vpc     = ibm_tg_connection.cluster_vpc_connection[0].name
    client_vpc      = var.create_client_vpc ? ibm_tg_connection.client_vpc_connection[0].name : "Client VPC not created"
  } : null
}


# ============================================================
# Kubeconfig Outputs
# ============================================================

output "kubeconfig_file_path" {
  description = "Path to the kubeconfig file for the OpenShift cluster (use default location)"
  value       = "~/.kube/config"
}

output "cluster_id" {
  description = "ID of the OpenShift cluster (alias for openshift_cluster_id)"
  value       = var.create_cluster ? ibm_container_vpc_cluster.openshift_cluster[0].id : null
}

output "cluster_name" {
  description = "Name of the OpenShift cluster (alias for openshift_cluster_name)"
  value       = var.create_cluster ? ibm_container_vpc_cluster.openshift_cluster[0].name : null
}
