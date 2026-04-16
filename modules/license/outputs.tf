# License Module Outputs

output "license_id" {
  description = "The name of the created License resource"
  value       = try(kubernetes_manifest.bnk_license[0].manifest.metadata.name, null)
}

output "license_namespace" {
  description = "The namespace where License CR is deployed"
  value       = try(kubernetes_manifest.bnk_license[0].manifest.metadata.namespace, var.utils_namespace)
}
