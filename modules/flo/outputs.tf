output "nad_crds_installed" {
  description = "NetworkAttachmentDefinition CRDs installation status"
  value       = "Installed from k8s-network-plumbing-wg"
}

output "nad_name" {
  description = "Name of the NetworkAttachmentDefinition resource"
  value       = local.nad_name_computed
}

output "nad_cni_type" {
  description = "CNI type used for NAD"
  value       = var.nad_cni_type
}

output "nad_interface" {
  description = "Network interface used for NAD"
  value       = var.nad_interface_name
}

output "cluster_issuers" {
  description = "List of ClusterIssuers created"
  value = [
    "selfsigned-cluster-issuer",
    "sample-issuer"
  ]
}

output "ca_certificate_name" {
  description = "Name of the CA certificate"
  value       = "arm-ca"
}

output "ca_secret_name" {
  description = "Name of the secret containing the CA certificate"
  value       = "arm-ca"
}

output "flo_release_name" {
  description = "Name of the f5-lifecycle-operator helm release"
  value       = var.enabled ? helm_release.f5_lifecycle_operator[0].name : null
}

output "flo_namespace" {
  description = "Namespace where f5-lifecycle-operator is installed"
  value       = var.enabled ? helm_release.f5_lifecycle_operator[0].namespace : null
}

output "flo_version" {
  description = "Version of f5-lifecycle-operator installed"
  value       = var.enabled ? helm_release.f5_lifecycle_operator[0].version : null
}

output "f5_utils_namespace" {
  description = "Namespace for F5 utility components"
  value       = var.enabled ? kubernetes_namespace.f5_utils[0].metadata[0].name : null
}

output "f5_bigip_k8s_manifest_version" {
  description = "Version of f5-bigip-k8s-manifest used"
  value       = var.f5_bigip_k8s_manifest_version
}

output "extracted_flo_version" {
  description = "FLO version extracted from f5-bigip-k8s-manifest"
  value       = var.enabled ? trimspace(data.local_file.flo_version[0].content) : null
}

output "extracted_cis_version" {
  description = "CIS version extracted from f5-bigip-k8s-manifest"
  value       = var.enabled ? trimspace(data.local_file.cis_version[0].content) : null
}

output "manifest_download_dir" {
  description = "Directory where manifest chart was downloaded and extracted"
  value       = var.manifest_download_dir
}

output "cneinstance_enabled" {
  description = "Whether CNEInstance was created"
  value       = var.cneinstance_enabled
}

output "cneinstance_name" {
  description = "Name of the CNEInstance resource"
  value       = var.cneinstance_enabled ? "${var.flo_namespace}-f5-cne-controller" : "N/A"
}

output "cneinstance_network_attachments" {
  description = "Network attachments configured for CNEInstance"
  value       = var.cneinstance_enabled ? local.cneinstance_network_attachments : []
}

output "nodes_labeled" {
  description = "All nodes have been labeled with app=f5-tmm"
  value       = "Applied to all cluster nodes"
}

output "cluster_issuer_name" {
  description = "Name of the cluster issuer"
  value       = var.cluster_issuer_name
}

output "flo_scc_policy_applied" {
  description = "Whether privileged SCC policy was applied to flo-f5-lifecycle-operator service account"
  value       = var.enabled ? (var.enabled ? "Applied: flo-f5-lifecycle-operator in ${var.flo_namespace}" : null) : null
}

output "flo_namespace_pods_count" {
  description = "Number of pods running in FLO namespace"
  value       = var.enabled ? length(data.kubernetes_resources.flo_namespace_pods[0].objects) : 0
}

output "flo_pod_deployment_status" {
  description = "Status of FLO pod deployment with pod counts and verification steps"
  value = var.enabled ? {
    pod_count           = length(data.kubernetes_resources.flo_namespace_pods[0].objects)
    scc_policy_count    = length(kubernetes_cluster_role_binding.flo_scc_privileged)
    namespace           = var.flo_namespace
    status_message      = "FLO pods deployed after SCC privileged policy applied"
    next_steps          = [
      "Verify pod status: kubectl get pods -n ${var.flo_namespace}",
      "Check pod logs: kubectl logs -n ${var.flo_namespace} <pod-name>",
      "Get pod details: kubectl describe pod -n ${var.flo_namespace} <pod-name>"
    ]
  } : null
}

output "cos_jwt_token" {
  description = "JWT token fetched from COS bucket (empty when use_cos_bucket = false)"
  value       = var.enabled && var.use_cos_bucket ? local.cos_jwt_token : ""
  sensitive   = true
}

output "trusted_profile_id" {
  description = "ID of the IBM IAM trusted profile created for the CNE controller service account"
  value       = local.global_enabled ? ibm_iam_trusted_profile.cne_controller[0].id : null
}
