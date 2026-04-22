locals {
  global_enabled = var.enabled
  
  far_registry_hostname = replace(var.far_repo_url, "https://", "")
  image_repository      = "${local.far_registry_hostname}/images"
  far_service_account_b64 = local.global_enabled ? (var.use_cos_bucket ? data.local_file.cne_pull_64_json_file[0].content : data.local_file.far_service_account_local[0].content) : ""
  far_auth_value = base64encode("_json_key_base64:${local.far_service_account_b64}")
  cos_jwt_token = local.global_enabled && var.use_cos_bucket ? trimspace(data.http.jwt_download[0].response_body) : var.jwt_token
  far_docker_config_json = replace(
    jsonencode({
      auths = {
        (local.far_registry_hostname) = {
          auth = local.far_auth_value
        }
      }
    }),
    ":",
    ": "
  )
  
  nad_name_computed = "ens3-ipvlan-l2"

  nad_config_host_device = jsonencode({
    cniVersion = "0.3.1"
    type       = "host-device"
    device     = var.nad_interface_name
  })

  nad_config_ipvlan = jsonencode({
    cniVersion = "0.3.1"
    type       = "ipvlan"
    master     = var.nad_interface_name
    mode       = var.nad_ipvlan_mode
    ipam = {
      type = "static"
      addresses = [
        {
          address = var.nad_ipvlan_address
        }
      ]
    }
  })

  cneinstance_network_attachments = [local.nad_name_computed, "macvlan-conf"]

  cis_helm_values = {
    global = {
      certmgr = {
        external = true
        issuerRef = {
          name = var.cluster_issuer_name
          kind = "ClusterIssuer"
        }
      }
    }

    rbac = {
      create = true
    }

    namespace = var.flo_namespace

    bigip_login_secret = "f5-bigip-ctlr-login"

    image = {
      repository = local.image_repository
      repo       = "f5-bnk-cis"
      pullSecrets = [
        "far-secret"
      ]
    }
  }

  flo_helm_values = {
    global = {
      imagePullSecrets = [
        {
          name = "far-secret"
        }
      ]
      certmgr = {
        clusterIssuer = var.cluster_issuer_name
      }
    }

    namespace = var.flo_namespace
    containerPlatform = "Generic"
    sharedComponentNamespace = var.utils_namespace

    image = {
      repository = local.image_repository
      pullPolicy = "Always"
    }

    "f5-spk-crds-common" = {
      versionValidator = {
        image = {
          repository = local.image_repository
        }
      }
    }

    "f5-spk-crds-service-proxy" = {
      versionValidator = {
        image = {
          repository = local.image_repository
        }
      }
    }

    "f5-ipam-operator" = {
      image = {
        repository = local.image_repository
        pullPolicy = "Always"
      }
      namespace        = var.flo_namespace
      nameOverride     = "f5-ipam-operator"
      fullnameOverride = "f5-ipam-operator"
    }

  }
}

# ==============================================================================
# FAR Service Account Key - Local File (when use_cos_bucket = false)
# ==============================================================================

data "local_file" "far_service_account_local" {
  count    = local.global_enabled && !var.use_cos_bucket ? 1 : 0
  filename = var.far_service_account_key_path
}

# ==============================================================================
# COS Bucket Resources (when use_cos_bucket = true)
# ==============================================================================

data "ibm_resource_groups" "all_resource_groups" {
  count = local.global_enabled && var.use_cos_bucket ? 1 : 0
}

data "ibm_resource_group" "resource_group" {
  count = local.global_enabled && var.use_cos_bucket ? 1 : 0
  name  = var.ibmcloud_resource_group != "" ? var.ibmcloud_resource_group : [
    for rg in data.ibm_resource_groups.all_resource_groups[0].resource_groups :
    rg.name if rg.is_default == true
  ][0]
}

data "ibm_resource_instance" "cos_instance" {
  count             = local.global_enabled && var.use_cos_bucket ? 1 : 0
  name              = var.ibmcloud_cos_instance_name
  resource_group_id = data.ibm_resource_group.resource_group[0].id
  service           = "cloud-object-storage"
}

data "ibm_cos_bucket" "cos_bucket" {
  count                = local.global_enabled && var.use_cos_bucket ? 1 : 0
  bucket_name          = var.ibmcloud_resources_cos_bucket
  resource_instance_id = data.ibm_resource_instance.cos_instance[0].id
  bucket_region        = var.ibmcloud_cos_bucket_region
  bucket_type          = "region_location"
}

data "ibm_cos_bucket_object" "f5_cne_subscription_jwt_object" {
  count           = local.global_enabled && var.use_cos_bucket ? 1 : 0
  bucket_crn      = data.ibm_cos_bucket.cos_bucket[0].crn
  bucket_location = data.ibm_cos_bucket.cos_bucket[0].bucket_region
  key             = var.f5_cne_subscription_jwt_file
}

# Download JWT file via COS S3-compatible REST API (body field may be empty for binary content_type)
data "http" "jwt_download" {
  count  = local.global_enabled && var.use_cos_bucket ? 1 : 0
  url    = "https://s3.${var.ibmcloud_cos_bucket_region}.cloud-object-storage.appdomain.cloud/${var.ibmcloud_resources_cos_bucket}/${var.f5_cne_subscription_jwt_file}"
  method = "GET"
  request_headers = {
    "Authorization"           = "Bearer ${jsondecode(data.http.iam_token[0].response_body).access_token}"
    "ibm-service-instance-id" = data.ibm_resource_instance.cos_instance[0].guid
  }
}

# Exchange API key for a short-lived IAM bearer token
data "http" "iam_token" {
  count  = local.global_enabled && var.use_cos_bucket ? 1 : 0
  url    = "https://iam.cloud.ibm.com/identity/token"
  method = "POST"
  request_headers = {
    "Content-Type" = "application/x-www-form-urlencoded"
    "Accept"       = "application/json"
  }
  request_body = "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=${var.ibmcloud_api_key}"
}

# Download the binary .tgz via the COS S3-compatible REST API
data "http" "far_archive_download" {
  count  = local.global_enabled && var.use_cos_bucket ? 1 : 0
  url    = "https://s3.${var.ibmcloud_cos_bucket_region}.cloud-object-storage.appdomain.cloud/${var.ibmcloud_resources_cos_bucket}/${var.f5_cne_far_auth_file}"
  method = "GET"
  request_headers = {
    "Authorization"           = "Bearer ${jsondecode(data.http.iam_token[0].response_body).access_token}"
    "ibm-service-instance-id" = data.ibm_resource_instance.cos_instance[0].guid
  }
}

resource "local_file" "temp_far_archive" {
  count          = local.global_enabled && var.use_cos_bucket ? 1 : 0
  content_base64 = data.http.far_archive_download[0].response_body_base64
  filename       = "/tmp/${var.f5_cne_far_auth_file}"
}

resource "null_resource" "cne_far_tgz_extractor" {
  count = local.global_enabled && var.use_cos_bucket ? 1 : 0

  triggers = {
    archive_id = local_file.temp_far_archive[0].id
  }

  provisioner "local-exec" {
    command = <<-EOT
      tar -xzf ${local_file.temp_far_archive[0].filename} -C /tmp/
      tar -tzf ${local_file.temp_far_archive[0].filename} | grep '\.json$' | head -1 > /tmp/far_extracted_filename.txt
    EOT
  }
}

data "local_file" "far_extracted_filename" {
  count      = local.global_enabled && var.use_cos_bucket ? 1 : 0
  filename   = "/tmp/far_extracted_filename.txt"
  depends_on = [null_resource.cne_far_tgz_extractor]
}

locals {
  far_extracted_filename = var.use_cos_bucket && local.global_enabled ? trimspace(data.local_file.far_extracted_filename[0].content) : ""
}

data "local_file" "cne_pull_64_json_file" {
  count      = local.global_enabled && var.use_cos_bucket ? 1 : 0
  filename   = "/tmp/${local.far_extracted_filename}"
  depends_on = [null_resource.cne_far_tgz_extractor]
}

# Fetch and apply NAD CRD using kubernetes_manifest
data "http" "nad_crd" {
  count = local.global_enabled ? 1 : 0
  url   = "https://raw.githubusercontent.com/k8snetworkplumbingwg/network-attachment-definition-client/master/artifacts/networks-crd.yaml"
}

resource "kubernetes_manifest" "nad_crd" {
  provider = kubernetes
  count    = 0 # CRD already exists in cluster

  manifest = yamldecode(data.http.nad_crd[0].response_body)
}

# Create NetworkAttachmentDefinition in FLO namespace using kubernetes_manifest
resource "kubernetes_manifest" "network_attachment_definition" {
  provider = kubernetes
  count    = local.global_enabled ? 1 : 0

  manifest = {
    apiVersion = "k8s.cni.cncf.io/v1"
    kind       = "NetworkAttachmentDefinition"
    metadata = {
      name      = local.nad_name_computed
      namespace = var.flo_namespace
    }
    spec = {
      config = var.nad_cni_type == "host-device" ? local.nad_config_host_device : local.nad_config_ipvlan
    }
  }

  depends_on = [
    kubernetes_namespace.flo_namespace
  ]
}

# Create macvlan NetworkAttachmentDefinition
resource "kubernetes_manifest" "macvlan_network_attachment_definition" {
  provider = kubernetes
  count    = local.global_enabled ? 1 : 0

  manifest = {
    apiVersion = "k8s.cni.cncf.io/v1"
    kind       = "NetworkAttachmentDefinition"
    metadata = {
      name      = "macvlan-conf"
      namespace = var.flo_namespace
    }
    spec = {
      config = jsonencode({
        cniVersion = "0.3.1"
        type       = "macvlan"
        master     = "dummy0"
        mode       = "bridge"
        ipam = {
          type = "static"
          addresses = [
            {
              address = "192.168.1.100/24"
              gateway = "192.168.1.1"
            }
          ]
        }
      })
    }
  }

  depends_on = [
    kubernetes_namespace.flo_namespace
  ]
}

# Apply ClusterIssuer manifest (cert-manager deployed by separate cert-manager module)
resource "kubernetes_manifest" "cluster_issuers" {
  provider = kubernetes
  count    = local.global_enabled ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "selfsigned-cluster-issuer"
    }
    spec = {
      selfSigned = {}
    }
  }

  depends_on = [
    var.cert_manager_crd_ready
  ]
}

# Self-signed certificate for CA
resource "kubernetes_manifest" "ca_certificate" {
  provider = kubernetes
  count    = local.global_enabled ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "ext-ca"
      namespace = var.cert_manager_namespace
    }
    spec = {
      isCA       = true
      commonName = "ext-ca"
      secretName = "ext-ca"
      issuerRef = {
        name  = "selfsigned-cluster-issuer"
        kind  = "ClusterIssuer"
        group = "cert-manager.io"
      }
    }
  }

  depends_on = [kubernetes_manifest.cluster_issuers[0]]
}

# CA cluster issuer
resource "kubernetes_manifest" "ca_cluster_issuer" {
  provider = kubernetes
  count    = local.global_enabled ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = var.cluster_issuer_name
    }
    spec = {
      ca = {
        secretName = "ext-ca"
      }
    }
  }

  depends_on = [kubernetes_manifest.ca_certificate[0]]
}

# Pull f5-bigip-k8s-manifest chart to extract FLO and CIS versions
resource "null_resource" "extract_flo_version" {
  count = local.global_enabled ? 1 : 0
  provisioner "local-exec" {
    command = <<-EOT
      set -e
      mkdir -p ${var.manifest_download_dir}
      cd ${var.manifest_download_dir}
      echo "${local.far_service_account_b64}" | helm registry login -u _json_key_base64 --password-stdin ${replace(var.far_repo_url, "https://", "")}
      helm pull oci://${replace(var.far_repo_url, "https://", "")}/release/f5-bigip-k8s-manifest --version "${var.f5_bigip_k8s_manifest_version}" -d .
      tar -xzf f5-bigip-k8s-manifest-${var.f5_bigip_k8s_manifest_version}.tgz
      FLO_VERSION=$(grep -A 1 "charts/f5-lifecycle-operator" f5-bigip-k8s-manifest-${var.f5_bigip_k8s_manifest_version}/bigip-k8s-manifest-${var.f5_bigip_k8s_manifest_version}.yaml | grep "version:" | awk '{print $2}' | tr -d '"' | tr -d "'")
      echo "$FLO_VERSION" > ${var.manifest_download_dir}/flo-version.txt
      CIS_VERSION=$(grep -A 1 "charts/f5-bnk-cis" f5-bigip-k8s-manifest-${var.f5_bigip_k8s_manifest_version}/bigip-k8s-manifest-${var.f5_bigip_k8s_manifest_version}.yaml | grep "version:" | awk '{print $2}' | tr -d '"' | tr -d "'")
      echo "$CIS_VERSION" > ${var.manifest_download_dir}/cis-version.txt
    EOT
  }

  triggers = {
    manifest_version = var.f5_bigip_k8s_manifest_version
  }

  depends_on = [null_resource.cne_far_tgz_extractor]
}

# Read the extracted FLO version
data "local_file" "flo_version" {
  count    = local.global_enabled ? 1 : 0
  filename = "${var.manifest_download_dir}/flo-version.txt"

  depends_on = [null_resource.extract_flo_version]
}

# Read the extracted CIS version
data "local_file" "cis_version" {
  count    = local.global_enabled ? 1 : 0
  filename = "${var.manifest_download_dir}/cis-version.txt"

  depends_on = [null_resource.extract_flo_version]
}

# Create f5-utils namespace
resource "kubernetes_namespace" "f5_utils" {
  provider = kubernetes
  count    = local.global_enabled ? 1 : 0
  metadata {
    name = var.utils_namespace
  }
}

# Create FLO namespace (skip if it's "default" - always exists)
resource "kubernetes_namespace" "flo_namespace" {
  provider = kubernetes
  count    = local.global_enabled && var.flo_namespace != "default" ? 1 : 0
  metadata {
    name = var.flo_namespace
  }
}

# Create BIG-IP login secret for CIS controller
resource "kubernetes_secret" "bigip_ctlr_login" {
  provider = kubernetes
  count    = local.global_enabled ? 1 : 0

  metadata {
    name      = "f5-bigip-ctlr-login"
    namespace = var.flo_namespace != "default" ? kubernetes_namespace.flo_namespace[0].metadata[0].name : "default"
  }

  data = {
    username = var.bigip_username
    password = var.bigip_password
    url      = replace(var.bigip_url, "https://", "")
  }

  depends_on = [
    kubernetes_namespace.flo_namespace
  ]
}

# Create FAR image pull secret using kubernetes_secret (removes local-exec)
resource "kubernetes_secret" "far_secret_flo" {
  provider = kubernetes
  count    = local.global_enabled ? 1 : 0

  metadata {
    name      = "far-secret"
    namespace = var.flo_namespace != "default" ? kubernetes_namespace.flo_namespace[0].metadata[0].name : "default"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = local.far_docker_config_json
  }

  depends_on = [
    kubernetes_namespace.flo_namespace
  ]
}

# Create FAR image pull secret in f5-utils namespace
resource "kubernetes_secret" "far_secret_utils" {
  provider = kubernetes
  count    = local.global_enabled ? 1 : 0

  metadata {
    name      = "far-secret"
    namespace = kubernetes_namespace.f5_utils[0].metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = local.far_docker_config_json
  }

  depends_on = [
    kubernetes_namespace.f5_utils
  ]
}

# Install f5-lifecycle-operator using Helm
resource "helm_release" "f5_lifecycle_operator" {
  provider = helm
  count    = local.global_enabled ? 1 : 0
  
  name                = "flo"
  repository          = "oci://${replace(var.far_repo_url, "https://", "")}/charts"
  chart               = "f5-lifecycle-operator"
  repository_username = "_json_key_base64"
  repository_password = local.far_service_account_b64
  version             = chomp(data.local_file.flo_version[0].content)
  namespace           = var.flo_namespace
  wait                = false
  timeout             = 300
  
  values = [yamlencode(local.flo_helm_values)]

  depends_on = [
    kubernetes_namespace.flo_namespace,
    kubernetes_secret.far_secret_flo,
    kubernetes_manifest.ca_cluster_issuer[0]
  ]
}

# Install f5-bnk-cis using Helm
resource "helm_release" "f5_bnk_cis" {
  provider = helm
  count    = local.global_enabled ? 1 : 0

  name                = "f5-bnk-cis"
  repository          = "oci://${replace(var.far_repo_url, "https://", "")}/charts"
  chart               = "f5-bnk-cis"
  repository_username = "_json_key_base64"
  repository_password = local.far_service_account_b64
  version             = chomp(data.local_file.cis_version[0].content)
  namespace           = var.flo_namespace
  wait                = false
  timeout             = 300

  values = [yamlencode(local.cis_helm_values)]

  depends_on = [
    kubernetes_namespace.flo_namespace,
    kubernetes_secret.far_secret_flo,
    kubernetes_manifest.ca_cluster_issuer[0],
  ]
}

# Apply privileged SCC to flo-f5-lifecycle-operator service account using Kubernetes RBAC
# This approach works with IBM Schematics and doesn't require 'oc' CLI
resource "kubernetes_cluster_role_binding" "flo_scc_privileged" {
  count = local.global_enabled ? 1 : 0

  metadata {
    name = "system:openshift:scc:privileged:${var.flo_namespace}:flo-f5-lifecycle-operator"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:openshift:scc:privileged"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "flo-f5-lifecycle-operator"
    namespace = var.flo_namespace
  }

  depends_on = [helm_release.f5_lifecycle_operator[0]]
}

# Apply privileged SCC to f5-bigip-ctlr-serviceaccount for CIS
resource "kubernetes_cluster_role_binding" "cis_scc_privileged" {
  count = local.global_enabled ? 1 : 0

  metadata {
    name = "system:openshift:scc:privileged:${var.flo_namespace}:f5-bigip-ctlr-serviceaccount"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:openshift:scc:privileged"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "f5-bigip-ctlr-serviceaccount"
    namespace = var.flo_namespace
  }

  depends_on = [helm_release.f5_bnk_cis[0]]
}

# Apply privileged SCC to default service account for CIS
resource "kubernetes_cluster_role_binding" "cis_default_scc_privileged" {
  count = local.global_enabled ? 1 : 0

  metadata {
    name = "system:openshift:scc:privileged:${var.flo_namespace}:default"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:openshift:scc:privileged"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = var.flo_namespace
  }

  depends_on = [helm_release.f5_bnk_cis[0]]
}

# Wait for SCC policies to be applied and pods to start
resource "time_sleep" "wait_for_flo_scc_policies" {
  count             = local.global_enabled ? 1 : 0
  create_duration   = "30s"
  triggers = {
    scc_policies_count = length(kubernetes_cluster_role_binding.flo_scc_privileged) + length(kubernetes_cluster_role_binding.cis_scc_privileged) + length(kubernetes_cluster_role_binding.cis_default_scc_privileged)
  }
  depends_on = [kubernetes_cluster_role_binding.flo_scc_privileged, kubernetes_cluster_role_binding.cis_scc_privileged, kubernetes_cluster_role_binding.cis_default_scc_privileged]
}

# Query pods in FLO namespace after SCC policies applied
data "kubernetes_resources" "flo_namespace_pods" {
  count = local.global_enabled ? 1 : 0
  
  api_version = "v1"
  kind        = "Pod"
  namespace   = var.flo_namespace
  
  depends_on = [time_sleep.wait_for_flo_scc_policies[0]]
}

# Create service account for node labeler
resource "kubernetes_service_account" "node_labeler" {
  provider = kubernetes
  count    = local.global_enabled ? 1 : 0

  metadata {
    name      = "node-labeler"
    namespace = "kube-system"
  }

  depends_on = [var.cert_manager_crd_ready]
}

# Create cluster role for node labeling
resource "kubernetes_manifest" "node_labeler_role" {
  provider = kubernetes
  count    = local.global_enabled ? 1 : 0

  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRole"
    metadata = {
      name = "node-labeler"
    }
    rules = [
      {
        apiGroups = [""]
        resources = ["nodes"]
        verbs     = ["get", "list", "patch", "update"]
      }
    ]
  }

  depends_on = [kubernetes_service_account.node_labeler[0]]
}

# Bind role to service account
resource "kubernetes_manifest" "node_labeler_binding" {
  provider = kubernetes
  count    = local.global_enabled ? 1 : 0

  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRoleBinding"
    metadata = {
      name = "node-labeler"
    }
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io"
      kind     = "ClusterRole"
      name     = "node-labeler"
    }
    subjects = [
      {
        kind      = "ServiceAccount"
        name      = "node-labeler"
        namespace = "kube-system"
      }
    ]
  }

  depends_on = [kubernetes_manifest.node_labeler_role[0]]
}

# Create a Job to label all nodes (runs via kubernetes provider, not local-exec)
resource "kubernetes_manifest" "node_labeler_job" {
  provider = kubernetes
  count    = local.global_enabled ? 1 : 0

  manifest = {
    apiVersion = "batch/v1"
    kind       = "Job"
    metadata = {
      name      = "node-labeler-${formatdate("YYYY-MM-DD-hhmm-ss", timestamp())}"
      namespace = "kube-system"
    }
    spec = {
      backoffLimit = 3
      template = {
        metadata = {
          name = "node-labeler"
        }
        spec = {
          serviceAccountName = "node-labeler"
          restartPolicy      = "Never"
          containers = [
            {
              name  = "labeler"
              image = "bitnami/kubectl:latest"
              command = [
                "/bin/sh",
                "-c",
                "kubectl label nodes --all app=f5-tmm --overwrite && echo 'All nodes labeled successfully'"
              ]
            }
          ]
        }
      }
    }
  }

  depends_on = [
    helm_release.f5_lifecycle_operator[0],
    kubernetes_manifest.node_labeler_binding[0]
  ]
}

# ==============================================================================
# IBM IAM Trusted Profile for CNE Controller Service Account
# ==============================================================================

resource "ibm_iam_trusted_profile" "cne_controller" {
  count       = local.global_enabled ? 1 : 0
  name        = "${var.openshift_cluster_name}-f5-cne-controller-${var.flo_namespace}"
  description = "Trusted profile for F5 CNE controller service account in namespace ${var.flo_namespace} on cluster ${var.openshift_cluster_name}"
}

resource "ibm_iam_trusted_profile_link" "cne_controller_roks" {
  count      = local.global_enabled ? 1 : 0
  profile_id = ibm_iam_trusted_profile.cne_controller[0].id
  cr_type    = "ROKS_SA"
  link {
    crn       = var.openshift_cluster_crn
    namespace = var.flo_namespace
    name      = "f5-cne-controller-${var.flo_namespace}-f5-cne-controller-serviceaccount"
  }
  name = "f5-cne-controller-roks-link"
}

resource "ibm_iam_trusted_profile_policy" "cne_controller_vpc" {
  count      = local.global_enabled ? 1 : 0
  profile_id = ibm_iam_trusted_profile.cne_controller[0].id
  roles      = ["Viewer", "Editor"]
  resources {
    service = "is"
  }
}
