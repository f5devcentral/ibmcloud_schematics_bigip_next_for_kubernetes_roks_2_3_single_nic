# CNEInstance Module Outputs

output "cneinstance_id" {
  description = "The ID of the created CNEInstance resource"
  value       = try(kubernetes_manifest.cneinstance[0].manifest.metadata.name, null)
}

output "cneinstance_namespace" {
  description = "The namespace where CNEInstance is deployed"
  value       = try(kubernetes_manifest.cneinstance[0].manifest.metadata.namespace, var.flo_namespace)
}

output "cneinstance_manifest" {
  description = "The full CNEInstance manifest"
  value       = try(kubernetes_manifest.cneinstance[0].manifest, null)
}

output "cneinstance_scc_policies_applied" {
  description = "Summary of SCC policies applied by CNEInstance module"
  value = {
    total_policies = length(local.scc_policy_assignments)
    flo_namespace_policies = [
      for assignment in local.scc_policy_assignments
      : "${assignment.namespace}/${assignment.service_account}" if assignment.namespace == var.flo_namespace
    ]
    f5_utils_policies = [
      for assignment in local.scc_policy_assignments
      : "${assignment.namespace}/${assignment.service_account}" if assignment.namespace == "f5-utils"
    ]
    policy_names = [
      for key, binding in kubernetes_cluster_role_binding.cneinstance_scc_policies : binding.metadata[0].name
    ]
  }
}

output "flo_namespace_pods_count" {
  description = "Number of pods in FLO namespace"
  value       = var.enabled ? try(length(data.kubernetes_resources.flo_namespace_pods[0].objects), 0) : 0
}

output "utils_namespace_pods_count" {
  description = "Number of pods in utilities namespace"
  value       = var.enabled ? try(length(data.kubernetes_resources.utils_namespace_pods[0].objects), 0) : 0
}

output "pod_deployment_status" {
  description = "Pod deployment status after readiness validation"
  value = var.enabled ? {
    flo_namespace_pod_count    = try(length(data.kubernetes_resources.flo_namespace_pods[0].objects), 0)
    utils_namespace_pod_count  = try(length(data.kubernetes_resources.utils_namespace_pods[0].objects), 0)
    flo_pods_not_ready         = local.flo_not_ready
    utils_pods_not_ready       = local.utils_not_ready
    scc_policies_applied       = length(kubernetes_cluster_role_binding.cneinstance_scc_policies)
    all_pods_running           = length(local.flo_not_ready) == 0 && length(local.utils_not_ready) == 0
  } : null
}
