locals {
  cneinstance_name = "${var.flo_namespace}-f5-cne-controller"
  
  # Define all service accounts that require privileged SCC
  # These service accounts are created by CNEInstance and FLO deployment
  scc_policy_assignments = concat(
    # f5-bnk namespace service accounts (if this is the main FLO namespace)
    var.flo_namespace == "f5-bnk" ? [
      {
        namespace = var.flo_namespace
        service_account = "f5-cne-env-discovery-serviceaccount"
      },
      {
        namespace = var.flo_namespace
        service_account = "tmm-sa"
      },
      {
        namespace = var.flo_namespace
        service_account = "f5-dssm"
      },
      {
        namespace = var.flo_namespace
        service_account = "f5-downloader"
      },
      {
        namespace = var.flo_namespace
        service_account = "f5-cne-controller-${var.flo_namespace}-f5-cne-controller-serviceaccount"
      },
      {
        namespace = var.flo_namespace
        service_account = "f5-afm"
      }
    ] : [],
    # f5-utils namespace service accounts
    [
      {
        namespace = var.utils_namespace
        service_account = "crd-installer"
      },
      {
        namespace = var.utils_namespace
        service_account = "cwc"
      },
      {
        namespace = var.utils_namespace
        service_account = "f5-coremond"
      },
      {
        namespace = var.utils_namespace
        service_account = "f5-crdconversion"
      },
      {
        namespace = var.utils_namespace
        service_account = "f5-observer-operator"
      },
      {
        namespace = var.utils_namespace
        service_account = "f5-rabbitmq"
      },
      {
        namespace = var.utils_namespace
        service_account = "f5-toda-fluentd-serviceaccount"
      },
      {
        namespace = var.utils_namespace
        service_account = "otel-sa"
      },
      {
        namespace = var.utils_namespace
        service_account = "default"
      },
      {
        namespace = var.utils_namespace
        service_account = "f5-ipam-ctlr"
      }
    ]
  )
  
  cneinstance_spec = {
    product = {
      gatewayAPI = var.cneinstance_gateway_api
      type       = "BNK"
    }
    manifestVersion = var.f5_bigip_k8s_manifest_version
    wholeCluster    = var.cneinstance_whole_cluster
    telemetry = {
      loggingSubsystem = {
        enabled = var.cneinstance_logging_subsystem
      }
      metricSubsystem = {
        enabled = var.cneinstance_metric_subsystem
      }
    }
    certificate = {
      clusterIssuer = var.cluster_issuer_name
    }
    deploymentSize = var.cneinstance_deployment_size
    registry = {
      uri = replace(var.far_repo_url, "https://", "")
      imagePullSecrets = [
        {
          name = "far-secret"
        }
      ]
      imagePullPolicy = "Always"
    }
    networkAttachments = var.cneinstance_network_attachments
    dynamicRouting = {
      enabled = var.cneinstance_dynamic_routing
    }
    firewallACL = {
      enabled = var.cneinstance_firewall_acl
    }
    pseudoCNI = {
      enabled = var.cneinstance_pseudocni
    }
    coreCollection = {
      enabled = true
    }
    advanced = {
      coremon = {
        hostPath = true
        env = [
          {
            name  = "COREMOND_OVERRIDE_CORE_PATTERN"
            value = "true"
          }
        ]
      }
      envDiscovery = {
        enabled         = var.cneinstance_env_discovery
        stopOnFail      = var.cneinstance_env_discovery
        runAfterSuccess = var.cneinstance_env_discovery
      }
      cneController = {
        env = [
          {
            name  = "TMM_DEFAULT_MTU"
            value = "9000"
          },
          {
            name  = "CLOUD_ENV"
            value = tostring(var.cneinstance_cloud_env)
          },
          {
            name  = "CLOUD_PROVIDER"
            value = var.cneinstance_cloud_provider
          },
          {
            name  = "CLOUD_NETWORK_CONFIGMAP"
            value = "cloud-network-mapping"
          },
          {
            name  = "VPC_NAME"
            value = var.cneinstance_vpc_name
          },
          {
            name  = "CLOUD_REGION"
            value = var.cneinstance_cloud_region
          },
          {
            name  = "IBM_TRUSTED_PROFILE_ID"
            value = var.cneinstance_ibm_trusted_profile_id
          },
          {
            name  = "GSLB_DATACENTER_NAME"
            value = var.cneinstance_gslb_datacenter_name
          }
        ]
      }
      demoMode = {
        enabled = true
      }
      maintenanceMode = {
        enabled = false
      }
      tmm = {
        env = [
          {
            name  = "TMM_CALICO_ROUTER"
            value = "default"
          },
          {
            name  = "TMM_DEFAULT_MTU"
            value = "9000"
          },
          {
            name  = "PAL_CPU_SET"
            value = "0,2"
          },
          {
            name  = "TMM_MAPRES_ADDL_VETHS_ON_DP"
            value = "TRUE"
          }
        ]
      }
      pseudoCNI = {
        env = [
          {
            name  = "DISABLE_CHECKSUM_OFFLOAD"
            value = "true"
          }
        ]
      }
    }
  }
}

# Wait for CNEInstance CRD to be available
resource "time_sleep" "wait_for_cneinstance_crd" {
  count            = var.enabled ? 1 : 0
  depends_on       = [var.flo_deployment_dependency]
  create_duration  = "30s"
  
  triggers = {
    flo_deployed = var.flo_deployment_id
  }
}

# Create CNEInstance resource 
resource "kubernetes_manifest" "cneinstance" {
  count = var.enabled ? 1 : 0

  field_manager {
    force_conflicts = true
  }

  manifest = {
    apiVersion = "k8s.f5.com/v1"
    kind       = "CNEInstance"
    metadata = {
      labels = {
        "app.kubernetes.io/name"       = "f5-lifecycle-operator"
        "app.kubernetes.io/managed-by" = "kustomize"
      }
      name      = local.cneinstance_name
      namespace = var.flo_namespace
    }
    spec = local.cneinstance_spec
  }

  depends_on = [time_sleep.wait_for_cneinstance_crd[0]]
}

# ============================================================
# OpenShift Security Context Constraint (SCC) Policies
# ============================================================
# Apply privileged SCC to service accounts created by CNEInstance deployment
# These policies are required for the F5 BNK and related components to function
# properly in OpenShift environments

resource "kubernetes_cluster_role_binding" "cneinstance_scc_policies" {
  for_each = { 
    for assignment in local.scc_policy_assignments : 
    "${assignment.namespace}-${assignment.service_account}" => assignment 
  }

  metadata {
    name = "system:openshift:scc:privileged:${each.value.namespace}:${each.value.service_account}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:openshift:scc:privileged"
  }

  subject {
    kind      = "ServiceAccount"
    name      = each.value.service_account
    namespace = each.value.namespace
  }

  depends_on = [kubernetes_manifest.cneinstance[0]]
}

# ============================================================
# Wait for SCC Policies to Propagate
# ============================================================
# After SCC policies are applied, wait briefly for Kubernetes
# to propagate the new permissions to pods.
# IBM Schematics compatible - no kubectl or local-exec needed.

resource "time_sleep" "wait_for_scc_policies" {
  count            = var.enabled ? 1 : 0
  depends_on       = [kubernetes_cluster_role_binding.cneinstance_scc_policies]
  create_duration  = "30s"
  
  triggers = {
    scc_policies_count = length(kubernetes_cluster_role_binding.cneinstance_scc_policies)
  }
}

# ============================================================
# Read Pod State After Wait
# ============================================================

data "kubernetes_resources" "flo_namespace_pods" {
  count       = var.enabled ? 1 : 0
  api_version = "v1"
  kind        = "Pod"
  namespace   = var.flo_namespace
  depends_on  = [time_sleep.wait_for_scc_policies[0]]

  lifecycle {
    postcondition {
      condition = length(self.objects) > 0
      error_message = "No pods found in namespace ${var.flo_namespace}. CNEInstance deployment may have failed."
    }
  }
}

data "kubernetes_resources" "utils_namespace_pods" {
  count       = var.enabled ? 1 : 0
  api_version = "v1"
  kind        = "Pod"
  namespace   = var.utils_namespace
  depends_on  = [time_sleep.wait_for_scc_policies[0]]

  lifecycle {
    postcondition {
      condition = length(self.objects) > 0
      error_message = "No pods found in namespace ${var.utils_namespace}. CNEInstance deployment may have failed."
    }
  }
}

# ============================================================
# Validate All Pods Are Running/Completed
# ============================================================

locals {
  flo_pods = var.enabled ? try(data.kubernetes_resources.flo_namespace_pods[0].objects, []) : []
  utils_pods = var.enabled ? try(data.kubernetes_resources.utils_namespace_pods[0].objects, []) : []

  flo_not_ready = [
    for pod in local.flo_pods :
    "${pod.metadata.name} (${try(pod.status.phase, "Unknown")})"
    if !contains(["Running", "Succeeded", "Completed"], try(pod.status.phase, ""))
  ]

  utils_not_ready = [
    for pod in local.utils_pods :
    "${pod.metadata.name} (${try(pod.status.phase, "Unknown")})"
    if !contains(["Running", "Succeeded", "Completed"], try(pod.status.phase, ""))
  ]
}

check "flo_pods_running" {
  assert {
    condition     = length(local.flo_not_ready) == 0
    error_message = "Pods not Running in ${var.flo_namespace}: ${join(", ", local.flo_not_ready)}"
  }
}

check "utils_pods_running" {
  assert {
    condition     = length(local.utils_not_ready) == 0
    error_message = "Pods not Running in ${var.utils_namespace}: ${join(", ", local.utils_not_ready)}"
  }
}

