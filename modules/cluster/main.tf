# Get all resource groups
data "ibm_resource_groups" "all_resource_groups" {}

# Get resource group - use default if not specified
data "ibm_resource_group" "resource_group" {
  name = var.resource_group != "" ? var.resource_group : [
    for rg in data.ibm_resource_groups.all_resource_groups.resource_groups :
    rg.name if rg.is_default == true
  ][0]
}

# Get available zones for the cluster region
data "ibm_is_zones" "regional_zones" {
  region = var.cluster_region
}

# Get available zones for client VPC region
data "ibm_is_zones" "client_region_zones" {
  region = var.client_vpc_region
}

# Get available OpenShift versions for the cluster region
data "ibm_container_cluster_versions" "cluster_versions" {}

# Use zones from variable or auto-detect from region
locals {
  zones               = length(var.zones) > 0 ? var.zones : data.ibm_is_zones.regional_zones.zones
  client_region_zones = data.ibm_is_zones.client_region_zones.zones

  # Select latest available OpenShift version or use user-specified version
  available_openshift_versions = data.ibm_container_cluster_versions.cluster_versions.valid_openshift_versions

  # Get the latest version by sorting and taking the last element
  # Always use the latest available version from the region
  openshift_version = "${reverse(sort(local.available_openshift_versions))[0]}_openshift"

  # VPC references (either created or existing)
  cluster_vpc_id = var.use_existing_cluster_vpc ? (
    var.existing_cluster_vpc_id != "" ? var.existing_cluster_vpc_id : data.ibm_is_vpc.existing_cluster_vpc[0].id
  ) : ibm_is_vpc.cluster_vpc[0].id

  cluster_vpc_crn = var.use_existing_cluster_vpc ? data.ibm_is_vpc.existing_cluster_vpc[0].crn : ibm_is_vpc.cluster_vpc[0].crn

  cluster_vpc_default_sg = var.use_existing_cluster_vpc ? data.ibm_is_vpc.existing_cluster_vpc[0].default_security_group : ibm_is_vpc.cluster_vpc[0].default_security_group

  client_vpc_id = !var.create_client_vpc ? null : (
    var.use_existing_client_vpc ? (
      var.existing_client_vpc_id != "" ? var.existing_client_vpc_id : data.ibm_is_vpc.existing_client_vpc[0].id
    ) : ibm_is_vpc.client_vpc[0].id
  )

  client_vpc_crn = !var.create_client_vpc ? null : (var.use_existing_client_vpc ? data.ibm_is_vpc.existing_client_vpc[0].crn : ibm_is_vpc.client_vpc[0].crn)

  client_vpc_default_sg = !var.create_client_vpc ? null : (var.use_existing_client_vpc ? data.ibm_is_vpc.existing_client_vpc[0].default_security_group : ibm_is_vpc.client_vpc[0].default_security_group)

  # Filter and select the latest Ubuntu 22.04 minimal image for client region
  client_ubuntu_images = var.create_client_vpc && var.create_jumphost && length(data.ibm_is_images.client_ubuntu_images) > 0 ? [
    for image in data.ibm_is_images.client_ubuntu_images[0].images :
    image if length(regexall("ubuntu-22-04.*minimal.*amd64", lower(image.name))) > 0
  ] : []
  client_jumphost_image_id = length(local.client_ubuntu_images) > 0 ? local.client_ubuntu_images[0].id : null

  # Dynamically select instance profile with minimum 4 vCPUs and 8GB RAM
  eligible_profiles = var.create_client_vpc && var.create_jumphost && length(data.ibm_is_instance_profiles.client_profiles) > 0 ? [
    for profile in data.ibm_is_instance_profiles.client_profiles[0].profiles :
    profile if profile.vcpu_count[0].value >= var.min_vcpu_count && profile.memory[0].value >= var.min_memory_gb
  ] : []

  client_jumphost_profile = var.jumphost_profile != "" ? var.jumphost_profile : (
    length(local.eligible_profiles) > 0 ? local.eligible_profiles[0].name : "bx2-4x16"
  )

  # Dynamically select worker flavor with minimum vCPUs and RAM
  # Use bx2 series (balanced) as it's most widely available across all regions
  # Supports any user-specified minimum requirements (scales from 2x8 to 128x512)
  # Available bx2 flavors: 2x8, 4x16, 8x32, 16x64, 32x128, 48x192, 64x256, 96x384, 128x512
  eligible_worker_profiles = [
    for profile in data.ibm_is_instance_profiles.cluster_worker_profiles.profiles :
    {
      name   = profile.name
      vcpu   = profile.vcpu_count[0].value
      memory = profile.memory[0].value
    }
    if profile.vcpu_count[0].value >= var.min_worker_vcpu_count &&
    profile.memory[0].value >= var.min_worker_memory_gb &&
    can(regex("^bx2-[0-9]+x[0-9]+$", profile.name))
  ]

  # Sort by vCPU first, then memory to get the smallest eligible flavor
  # Transform dash notation to period notation for OpenShift cluster flavors
  cluster_worker_flavor = var.worker_flavor != "" ? var.worker_flavor : (
    length(local.eligible_worker_profiles) > 0 ?
    replace(
      [
        for p in local.eligible_worker_profiles :
        p.name if p.vcpu == min([for prof in local.eligible_worker_profiles : prof.vcpu]...) &&
        p.memory == min([for prof in local.eligible_worker_profiles : prof.memory if prof.vcpu == min([for pr in local.eligible_worker_profiles : pr.vcpu]...)]...)
      ][0],
      "-", "."
    ) : "bx2.4x16"
  )
}

# Data source to look up existing cluster VPC (if using existing)
data "ibm_is_vpc" "existing_cluster_vpc" {
  count = var.use_existing_cluster_vpc ? 1 : 0
  name  = var.cluster_vpc_name
}

# Create Cluster VPC (only if not using existing)
resource "ibm_is_vpc" "cluster_vpc" {
  count          = var.use_existing_cluster_vpc ? 0 : 1
  name           = var.cluster_vpc_name
  resource_group = data.ibm_resource_group.resource_group.id
  tags           = ["terraform", "cluster"]
}

# Get available instance profiles in cluster region for worker node selection
data "ibm_is_instance_profiles" "cluster_worker_profiles" {
  # Profiles are region-agnostic, but we'll filter based on requirements
}

# ============================================================
# Client Region Resources - Client VPC and Jumphost
# ============================================================

# Provider alias for Client region
provider "ibm" {
  alias            = "client_region"
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.client_vpc_region
}

# Data source to look up existing client VPC (if using existing)
data "ibm_is_vpc" "existing_client_vpc" {
  count    = var.create_client_vpc && var.use_existing_client_vpc ? 1 : 0
  provider = ibm.client_region
  name     = var.client_vpc_name
}

# Create Client VPC (only if not using existing)
resource "ibm_is_vpc" "client_vpc" {
  count          = var.create_client_vpc && !var.use_existing_client_vpc ? 1 : 0
  provider       = ibm.client_region
  name           = var.client_vpc_name
  resource_group = data.ibm_resource_group.resource_group.id
  tags           = ["terraform", "client"]
}

# Create subnet for client jumphost in Sydney zone 1
resource "ibm_is_subnet" "client_jumphost_subnet" {
  count                    = var.create_client_vpc && var.create_jumphost ? 1 : 0
  provider                 = ibm.client_region
  name                     = "${var.client_jumphost_name}-subnet"
  vpc                      = local.client_vpc_id
  zone                     = local.client_region_zones[0]
  total_ipv4_address_count = 256
  resource_group           = data.ibm_resource_group.resource_group.id
}

# Get SSH key in Sydney region
data "ibm_is_ssh_key" "ssh_key_client_region" {
  count    = var.create_client_vpc && var.create_jumphost && var.ssh_key_name != "" ? 1 : 0
  provider = ibm.client_region
  name     = var.ssh_key_name
}

# Get OS image for client jumphost in Sydney - dynamically select latest Ubuntu 22.04
data "ibm_is_images" "client_ubuntu_images" {
  count      = var.create_client_vpc && var.create_jumphost ? 1 : 0
  provider   = ibm.client_region
  visibility = "public"
  status     = "available"
}

# Get available instance profiles in Sydney region
data "ibm_is_instance_profiles" "client_profiles" {
  count    = var.create_client_vpc && var.create_jumphost ? 1 : 0
  provider = ibm.client_region
}

# Create security group for client jumphost
resource "ibm_is_security_group" "client_jumphost_sg" {
  count          = var.create_client_vpc && var.create_jumphost ? 1 : 0
  provider       = ibm.client_region
  name           = "${var.client_jumphost_name}-sg"
  vpc            = local.client_vpc_id
  resource_group = data.ibm_resource_group.resource_group.id
}

# Allow SSH inbound for client jumphost
resource "ibm_is_security_group_rule" "client_jumphost_ssh_inbound" {
  count     = var.create_client_vpc && var.create_jumphost ? 1 : 0
  provider  = ibm.client_region
  group     = ibm_is_security_group.client_jumphost_sg[0].id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  protocol  = "tcp"
  port_min  = 22
  port_max  = 22
}

# Allow all outbound for client jumphost
resource "ibm_is_security_group_rule" "client_jumphost_outbound" {
  count     = var.create_client_vpc && var.create_jumphost ? 1 : 0
  provider  = ibm.client_region
  group     = ibm_is_security_group.client_jumphost_sg[0].id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# Create public gateway for client jumphost internet access
resource "ibm_is_public_gateway" "client_jumphost_gateway" {
  count          = var.create_client_vpc && var.create_jumphost ? 1 : 0
  provider       = ibm.client_region
  name           = "${var.client_jumphost_name}-gateway"
  vpc            = local.client_vpc_id
  zone           = local.client_region_zones[0]
  resource_group = data.ibm_resource_group.resource_group.id
}

# Attach public gateway to client jumphost subnet
resource "ibm_is_subnet_public_gateway_attachment" "client_jumphost_subnet_gateway" {
  count          = var.create_client_vpc && var.create_jumphost ? 1 : 0
  provider       = ibm.client_region
  subnet         = ibm_is_subnet.client_jumphost_subnet[0].id
  public_gateway = ibm_is_public_gateway.client_jumphost_gateway[0].id
}

# Create client jumphost instance in Sydney
resource "ibm_is_instance" "client_jumphost" {
  count          = var.create_client_vpc && var.create_jumphost ? 1 : 0
  provider       = ibm.client_region
  name           = var.client_jumphost_name
  vpc            = local.client_vpc_id
  zone           = local.client_region_zones[0]
  profile        = local.client_jumphost_profile
  image          = local.client_jumphost_image_id
  keys           = [data.ibm_is_ssh_key.ssh_key_client_region[0].id]
  resource_group = data.ibm_resource_group.resource_group.id

  primary_network_interface {
    subnet          = ibm_is_subnet.client_jumphost_subnet[0].id
    security_groups = [ibm_is_security_group.client_jumphost_sg[0].id, local.client_vpc_default_sg]
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update system
    apt-get update
    apt-get upgrade -y

    # Install required dependencies
    apt-get install -y curl wget apt-transport-https ca-certificates gnupg lsb-release software-properties-common

    # Install IBM Cloud CLI
    curl -fsSL https://clis.cloud.ibm.com/install/linux | sh

    # Install Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ubuntu

    # Install Helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl

    # Install OpenShift CLI (oc)
    wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz
    tar -xzf openshift-client-linux.tar.gz
    install -o root -g root -m 0755 oc /usr/local/bin/oc
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm -f openshift-client-linux.tar.gz oc kubectl

    # Install IBM Cloud plugins
    ibmcloud plugin install container-service -f
    ibmcloud plugin install openshift -f
    ibmcloud plugin install vpc-infrastructure -f

    # Create installation marker
    echo "Package installation completed at $(date)" > /var/log/jumphost-setup.log
    EOF

  tags = ["terraform", "client", "jumphost"]
}

# Reserve and associate floating IP for client jumphost
resource "ibm_is_floating_ip" "client_jumphost_fip" {
  count          = var.create_client_vpc && var.create_jumphost ? 1 : 0
  provider       = ibm.client_region
  name           = "${var.client_jumphost_name}-fip"
  target         = ibm_is_instance.client_jumphost[0].primary_network_interface[0].id
  resource_group = data.ibm_resource_group.resource_group.id
  tags           = ["terraform", "client", "jumphost"]
}


# ============================================================
# OpenShift Cluster Resources
# ============================================================

# Create subnets for OpenShift cluster in each zone
resource "ibm_is_subnet" "cluster_subnet_zone1" {
  count                    = var.create_cluster ? 1 : 0
  name                     = "${var.openshift_cluster_name}-subnet-zone1"
  vpc                      = local.cluster_vpc_id
  zone                     = local.zones[0]
  total_ipv4_address_count = 256
  resource_group           = data.ibm_resource_group.resource_group.id
}

resource "ibm_is_subnet" "cluster_subnet_zone2" {
  count                    = var.create_cluster ? 1 : 0
  name                     = "${var.openshift_cluster_name}-subnet-zone2"
  vpc                      = local.cluster_vpc_id
  zone                     = local.zones[1]
  total_ipv4_address_count = 256
  resource_group           = data.ibm_resource_group.resource_group.id
}

resource "ibm_is_subnet" "cluster_subnet_zone3" {
  count                    = var.create_cluster ? 1 : 0
  name                     = "${var.openshift_cluster_name}-subnet-zone3"
  vpc                      = local.cluster_vpc_id
  zone                     = local.zones[2]
  total_ipv4_address_count = 256
  resource_group           = data.ibm_resource_group.resource_group.id
}

# Create public gateways for cluster subnets
resource "ibm_is_public_gateway" "cluster_gateway_zone1" {
  count          = var.create_cluster ? 1 : 0
  name           = "${var.openshift_cluster_name}-gateway-zone1"
  vpc            = local.cluster_vpc_id
  zone           = local.zones[0]
  resource_group = data.ibm_resource_group.resource_group.id
}

resource "ibm_is_public_gateway" "cluster_gateway_zone2" {
  count          = var.create_cluster ? 1 : 0
  name           = "${var.openshift_cluster_name}-gateway-zone2"
  vpc            = local.cluster_vpc_id
  zone           = local.zones[1]
  resource_group = data.ibm_resource_group.resource_group.id
}

resource "ibm_is_public_gateway" "cluster_gateway_zone3" {
  count          = var.create_cluster ? 1 : 0
  name           = "${var.openshift_cluster_name}-gateway-zone3"
  vpc            = local.cluster_vpc_id
  zone           = local.zones[2]
  resource_group = data.ibm_resource_group.resource_group.id
}

# Attach public gateways to cluster subnets
resource "ibm_is_subnet_public_gateway_attachment" "cluster_subnet_gateway_zone1" {
  count          = var.create_cluster ? 1 : 0
  subnet         = ibm_is_subnet.cluster_subnet_zone1[0].id
  public_gateway = ibm_is_public_gateway.cluster_gateway_zone1[0].id
}

resource "ibm_is_subnet_public_gateway_attachment" "cluster_subnet_gateway_zone2" {
  count          = var.create_cluster ? 1 : 0
  subnet         = ibm_is_subnet.cluster_subnet_zone2[0].id
  public_gateway = ibm_is_public_gateway.cluster_gateway_zone2[0].id
}

resource "ibm_is_subnet_public_gateway_attachment" "cluster_subnet_gateway_zone3" {
  count          = var.create_cluster ? 1 : 0
  subnet         = ibm_is_subnet.cluster_subnet_zone3[0].id
  public_gateway = ibm_is_public_gateway.cluster_gateway_zone3[0].id
}

# Allow TCP port 80 from any source (using cluster security group)
resource "ibm_is_security_group_rule" "cluster_tcp_80" {
  count     = var.create_cluster ? 1 : 0
  group     = local.cluster_security_group
  direction = "inbound"
  remote    = "0.0.0.0/0"
  protocol  = "tcp"
  port_min  = 80
  port_max  = 80

  depends_on = [ibm_container_vpc_cluster.openshift_cluster]
}


# Add inbound rule to cluster VPC default security group to allow all traffic
resource "ibm_is_security_group_rule" "cluster_sg_inbound_all" {
  group     = local.cluster_vpc_default_sg
  direction = "inbound"
  remote    = "0.0.0.0/0"
}

# Add inbound rule to client VPC default security group to allow all traffic
resource "ibm_is_security_group_rule" "client_sg_inbound_all" {
  count     = var.create_client_vpc ? 1 : 0
  provider  = ibm.client_region
  group     = local.client_vpc_default_sg
  direction = "inbound"
  remote    = "0.0.0.0/0"
}

# Create Cloud Object Storage instance for OpenShift registry (Optional)
resource "ibm_resource_instance" "cos_instance" {
  count             = var.create_cluster && var.create_cos_instance ? 1 : 0
  name              = var.cos_instance_name != "" ? var.cos_instance_name : "${var.openshift_cluster_name}-cos"
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
  resource_group_id = data.ibm_resource_group.resource_group.id
  tags              = ["terraform", "openshift"]
}

# Create OpenShift cluster
resource "ibm_container_vpc_cluster" "openshift_cluster" {
  count             = var.create_cluster ? 1 : 0
  name              = var.openshift_cluster_name
  vpc_id            = local.cluster_vpc_id
  flavor            = local.cluster_worker_flavor
  worker_count      = var.workers_per_zone
  kube_version      = local.openshift_version
  resource_group_id = data.ibm_resource_group.resource_group.id
  cos_instance_crn  = var.create_cos_instance ? ibm_resource_instance.cos_instance[0].crn : null

  zones {
    subnet_id = ibm_is_subnet.cluster_subnet_zone1[0].id
    name      = local.zones[0]
  }

  zones {
    subnet_id = ibm_is_subnet.cluster_subnet_zone2[0].id
    name      = local.zones[1]
  }

  zones {
    subnet_id = ibm_is_subnet.cluster_subnet_zone3[0].id
    name      = local.zones[2]
  }

  disable_public_service_endpoint     = false
  disable_outbound_traffic_protection = true

  tags = ["terraform", "openshift"]

  timeouts {
    create = "120m"
    delete = "90m"
  }

  depends_on = [
    ibm_is_subnet.cluster_subnet_zone1,
    ibm_is_subnet.cluster_subnet_zone2,
    ibm_is_subnet.cluster_subnet_zone3,
    ibm_is_subnet_public_gateway_attachment.cluster_subnet_gateway_zone1,
    ibm_is_subnet_public_gateway_attachment.cluster_subnet_gateway_zone2,
    ibm_is_subnet_public_gateway_attachment.cluster_subnet_gateway_zone3
  ]
}

# Wait for cluster to be fully ready: state, workers, ingress, then operators
resource "null_resource" "wait_for_cluster_ready" {
  count = var.create_cluster && !var.skip_cluster_health_check ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      #!/bin/bash

      CLUSTER_ID="${ibm_container_vpc_cluster.openshift_cluster[0].id}"
      MAX_ATTEMPTS=15
      SLEEP_INTERVAL=10

      echo "=========================================="
      echo "Starting Cluster Health Validation"
      echo "Cluster ID: $CLUSTER_ID"
      echo "=========================================="

      check_cluster_state() {
        ibmcloud ks cluster get --cluster "$CLUSTER_ID" --output json 2>/dev/null | python3 -c "import sys, json; print(json.load(sys.stdin).get('state', 'pending'))" 2>/dev/null || echo "pending"
      }

      check_workers() {
        ibmcloud ks workers --cluster "$CLUSTER_ID" --output json 2>/dev/null | python3 -c "
import sys, json
try:
    workers = json.load(sys.stdin)
    ready = sum(1 for w in workers if w.get('health', {}).get('state') == 'normal' and w.get('health', {}).get('message') == 'Ready')
    print(ready)
except:
    print('0')
" 2>/dev/null || echo "0"
      }

      check_ingress() {
        ibmcloud ks cluster get --cluster "$CLUSTER_ID" --output json 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    status = data.get('ingress', {}).get('status', data.get('ingressStatus', 'unknown'))
    print(status)
except:
    print('unknown')
" 2>/dev/null || echo "unknown"
      }

      echo ""
      echo "Phase 1: Waiting for cluster state to be 'normal'..."
      for i in $(seq 1 $MAX_ATTEMPTS); do
        STATE=$(check_cluster_state)
        echo "[Attempt $i/$MAX_ATTEMPTS] Cluster state: $STATE"
        if [ "$STATE" = "normal" ]; then
          echo "✓ Cluster state is normal"
          break
        fi
        if [ $i -eq $MAX_ATTEMPTS ]; then
          echo "ERROR: Cluster did not reach 'normal' state within timeout"
        fi
        sleep $SLEEP_INTERVAL
      done

      echo ""
      echo "Phase 2: Waiting for all worker nodes to be ready..."
      EXPECTED_WORKERS=3
      WORKERS_FOUND=false
      for i in $(seq 1 $MAX_ATTEMPTS); do
        WORKERS_READY=$(check_workers)
        echo "[Attempt $i/$MAX_ATTEMPTS] Workers ready: $WORKERS_READY/$EXPECTED_WORKERS"
        if [ "$WORKERS_READY" -ge "$EXPECTED_WORKERS" ]; then
          echo "✓ All $EXPECTED_WORKERS workers are ready"
          WORKERS_FOUND=true
          break
        fi
        sleep $SLEEP_INTERVAL
      done
      if [ "$WORKERS_FOUND" = "false" ]; then
        echo "WARNING: Not all workers ready within timeout (found $WORKERS_READY/$EXPECTED_WORKERS)"
      fi

      echo ""
      echo "Phase 3: Waiting for Ingress to be healthy..."
      INGRESS_FOUND=false
      for i in $(seq 1 $MAX_ATTEMPTS); do
        INGRESS_STATUS=$(check_ingress)
        echo "[Attempt $i/$MAX_ATTEMPTS] Ingress status: $INGRESS_STATUS"
        if [ "$INGRESS_STATUS" = "healthy" ]; then
          echo "✓ Ingress is healthy"
          INGRESS_FOUND=true
          break
        fi
        sleep $SLEEP_INTERVAL
      done
      if [ "$INGRESS_FOUND" = "false" ]; then
        echo "WARNING: Ingress did not reach 'healthy' state (current: $INGRESS_STATUS)"
        echo "This may resolve automatically. Check 'ibmcloud ks ingress status-report get' after apply."
      fi

      echo ""
      echo "Phase 4: Validating cluster operators..."
      ibmcloud ks cluster config --cluster $CLUSTER_ID --admin > /dev/null 2>&1
      if ! command -v kubectl &> /dev/null; then
        echo "WARNING: kubectl not found. Skipping operator validation."
      else
        MAX_ATTEMPTS=20
        for i in $(seq 1 $MAX_ATTEMPTS); do
          echo "[Attempt $i/$MAX_ATTEMPTS] Checking cluster operators..."
          if ! kubectl get co &> /dev/null; then
            echo "  API not ready yet, waiting..."
            sleep 30
            continue
          fi
          DEGRADED=$(kubectl get co -o json 2>/dev/null | python3 -c "
import sys, json
try:
    operators = json.load(sys.stdin)['items']
    degraded = [op['metadata']['name'] for op in operators
                if any(c.get('type') == 'Degraded' and c.get('status') == 'True'
                       for c in op.get('status', {}).get('conditions', []))]
    print(len(degraded))
except:
    print('999')
" 2>/dev/null || echo "999")
          UNAVAILABLE=$(kubectl get co -o json 2>/dev/null | python3 -c "
import sys, json
try:
    operators = json.load(sys.stdin)['items']
    unavailable = [op['metadata']['name'] for op in operators
                   if any(c.get('type') == 'Available' and c.get('status') == 'False'
                          for c in op.get('status', {}).get('conditions', []))]
    print(len(unavailable))
except:
    print('999')
" 2>/dev/null || echo "999")
          echo "  Degraded: $DEGRADED | Unavailable: $UNAVAILABLE"
          if [ "$DEGRADED" = "0" ] && [ "$UNAVAILABLE" = "0" ]; then
            echo "✓ All cluster operators are healthy!"
            kubectl get co 2>/dev/null | head -10
            break
          fi
          if [ $i -eq $MAX_ATTEMPTS ]; then
            echo "WARNING: Some operators are still not ready after timeout"
            kubectl get co 2>/dev/null || echo "Unable to query operators"
          fi
          sleep 30
        done
      fi

      echo ""
      echo "=========================================="
      echo "Cluster Ready"
      echo "State: $(check_cluster_state) | Workers: $(check_workers)/$EXPECTED_WORKERS | Ingress: $(check_ingress)"
      echo "=========================================="
      exit 0

    EOT
  }

  depends_on = [ibm_container_vpc_cluster.openshift_cluster]
}

# Get worker nodes details
data "ibm_container_vpc_cluster" "cluster_info" {
  count             = var.create_cluster ? 1 : 0
  name              = ibm_container_vpc_cluster.openshift_cluster[0].name
  resource_group_id = data.ibm_resource_group.resource_group.id

  depends_on = [null_resource.wait_for_cluster_ready, ibm_container_vpc_cluster.openshift_cluster]
}

# Get the cluster security group by name pattern kube-<cluster_id>
data "ibm_is_security_group" "cluster_sg" {
  count = var.create_cluster ? 1 : 0
  name  = "kube-${ibm_container_vpc_cluster.openshift_cluster[0].id}"
}

# Get worker node IPs from cluster workers
data "ibm_container_vpc_cluster_worker" "cluster_workers" {
  count             = var.create_cluster ? 3 : 0
  cluster_name_id   = ibm_container_vpc_cluster.openshift_cluster[0].id
  worker_id         = element(data.ibm_container_vpc_cluster.cluster_info[0].workers, count.index)
  resource_group_id = data.ibm_resource_group.resource_group.id
}

# Map worker nodes to their respective zones
locals {
  # Create a map of zone to worker IP (only when cluster is created)
  zone_worker_map = var.create_cluster && length(data.ibm_container_vpc_cluster_worker.cluster_workers) > 0 ? {
    for worker in data.ibm_container_vpc_cluster_worker.cluster_workers :
    worker.network_interfaces[0].subnet_id => worker.network_interfaces[0].ip_address
  } : {}

  # Get zone-specific worker IPs
  zone1_worker_ip = var.create_cluster && length(local.zone_worker_map) > 0 ? local.zone_worker_map[ibm_is_subnet.cluster_subnet_zone1[0].id] : null
  zone2_worker_ip = var.create_cluster && length(local.zone_worker_map) > 0 ? local.zone_worker_map[ibm_is_subnet.cluster_subnet_zone2[0].id] : null
  zone3_worker_ip = var.create_cluster && length(local.zone_worker_map) > 0 ? local.zone_worker_map[ibm_is_subnet.cluster_subnet_zone3[0].id] : null

  # Get cluster security group from data source
  cluster_security_group = var.create_cluster && length(data.ibm_is_security_group.cluster_sg) > 0 ? data.ibm_is_security_group.cluster_sg[0].id : null
}

# ============================================================
# Transit Gateway
# ============================================================

# Create Transit Gateway with global routing
resource "ibm_tg_gateway" "transit_gateway" {
  count                          = var.create_transit_gateway ? 1 : 0
  name                           = var.transit_gateway_name
  location                       = var.cluster_region
  global                         = true
  resource_group                 = data.ibm_resource_group.resource_group.id
  gre_enhanced_route_propagation = true
  tags                           = ["terraform", "transit-gateway"]
}

# Connect cluster-vpc to Transit Gateway (only when both transit gateway and cluster are created/used)
resource "ibm_tg_connection" "cluster_vpc_connection" {
  count        = var.create_transit_gateway && var.create_cluster ? 1 : 0
  gateway      = ibm_tg_gateway.transit_gateway[0].id
  network_type = "vpc"
  name         = var.cluster_vpc_name
  network_id   = local.cluster_vpc_crn
}

# Connect client-vpc to Transit Gateway (only when both transit gateway and client VPC are created)
resource "ibm_tg_connection" "client_vpc_connection" {
  count        = var.create_transit_gateway && var.create_client_vpc ? 1 : 0
  gateway      = ibm_tg_gateway.transit_gateway[0].id
  network_type = "vpc"
  name         = var.client_vpc_name
  network_id   = local.client_vpc_crn
}

