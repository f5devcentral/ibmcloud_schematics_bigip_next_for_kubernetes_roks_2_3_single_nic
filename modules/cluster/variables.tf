variable "ibmcloud_api_key" {
  description = "IBM Cloud API key"
  type        = string
  sensitive   = true
}

variable "cluster_region" {
  description = "IBM Cloud region for cluster"
  type        = string
  default     = "ca-tor"

  validation {
    condition     = length(var.cluster_region) > 0
    error_message = "cluster_region cannot be empty"
  }
}

variable "resource_group" {
  description = "Resource group name (leave empty to use account default resource group)"
  type        = string
  default     = ""
}

variable "cluster_vpc_name" {
  description = "Name of the cluster VPC (used for creation or lookup)"
  type        = string
  default     = "tf-cluster-vpc"
}

variable "use_existing_cluster_vpc" {
  description = "Set to true to use an existing cluster VPC instead of creating a new one"
  type        = bool
  default     = false
}

variable "existing_cluster_vpc_id" {
  description = "ID of existing cluster VPC (required if use_existing_cluster_vpc is true)"
  type        = string
  default     = ""
}

variable "zones" {
  description = "Availability zones (optional - will auto-detect from region if not specified)"
  type        = list(string)
  default     = []
}

# variable "zone1_prefix_cidr" {
#   description = "CIDR block for zone 1 address prefix"
#   type        = string
#   default     = "10.155.0.0/24"
#
#   validation {
#     condition     = can(cidrhost(var.zone1_prefix_cidr, 0))
#     error_message = "zone1_prefix_cidr must be a valid CIDR block (e.g., 10.155.0.0/24)"
#   }
# }

# variable "zone2_prefix_cidr" {
#   description = "CIDR block for zone 2 address prefix"
#   type        = string
#   default     = "10.156.0.0/24"
#
#   validation {
#     condition     = can(cidrhost(var.zone2_prefix_cidr, 0))
#     error_message = "zone2_prefix_cidr must be a valid CIDR block (e.g., 10.156.0.0/24)"
#   }
# }

# variable "zone3_prefix_cidr" {
#   description = "CIDR block for zone 3 address prefix"
#   type        = string
#   default     = "10.157.0.0/24"
#
#   validation {
#     condition     = can(cidrhost(var.zone3_prefix_cidr, 0))
#     error_message = "zone3_prefix_cidr must be a valid CIDR block (e.g., 10.157.0.0/24)"
#   }
# }

# variable "zone1_virtual_ip" {
#   description = "Virtual IP address for zone 1 load balancer member"
#   type        = string
#   default     = "10.155.15.101"
# }

# variable "zone2_virtual_ip" {
#   description = "Virtual IP address for zone 2 load balancer member"
#   type        = string
#   default     = "10.156.16.101"
# }

# variable "zone3_virtual_ip" {
#   description = "Virtual IP address for zone 3 load balancer member"
#   type        = string
#   default     = "10.157.17.101"
# }

variable "create_jumphost" {
  description = "Enable creation of jumphost instance in client VPC"
  type        = bool
  default     = false
}

variable "ssh_key_name" {
  description = "Name of the SSH key to use for jumphost (required only when create_jumphost is true)"
  type        = string
  default     = ""
}

variable "client_vpc_region" {
  description = "Region for client VPC"
  type        = string
  default     = "au-syd"
}

variable "client_vpc_name" {
  description = "Name of the client VPC (used for creation or lookup)"
  type        = string
  default     = "tf-client-vpc"
}

variable "create_client_vpc" {
  description = "Enable creation of client VPC"
  type        = bool
  default     = false
}

variable "use_existing_client_vpc" {
  description = "Set to true to use an existing client VPC instead of creating a new one (only used if create_client_vpc is true)"
  type        = bool
  default     = false
}

variable "existing_client_vpc_id" {
  description = "ID of existing client VPC (required if use_existing_client_vpc is true)"
  type        = string
  default     = ""
}

variable "client_jumphost_name" {
  description = "Name of the client jumphost instance"
  type        = string
  default     = "tf-client-jh"
}

variable "jumphost_profile" {
  description = "Instance profile for jumphost (optional - will auto-select based on min requirements if not specified)"
  type        = string
  default     = ""
}

variable "min_vcpu_count" {
  description = "Minimum number of vCPUs for client jumphost (used when auto-selecting profile)"
  type        = number
  default     = 4
}

variable "min_memory_gb" {
  description = "Minimum memory in GB for client jumphost (used when auto-selecting profile)"
  type        = number
  default     = 8
}

variable "create_cluster" {
  description = "Enable creation of OpenShift cluster"
  type        = bool
  default     = false
}

variable "create_cos_instance" {
  description = "Enable creation of Cloud Object Storage instance for OpenShift registry"
  type        = bool
  default     = true
}

variable "openshift_cluster_name" {
  description = "Name of the OpenShift cluster"
  type        = string
  default     = "tf-cluster"
}

variable "worker_pool_name" {
  description = "Worker pool name"
  type        = string
  default     = "tf-worker-pool"
}

variable "worker_flavor" {
  description = "Worker node flavor (optional - will auto-select based on min requirements if not specified)"
  type        = string
  default     = ""
}

variable "min_worker_vcpu_count" {
  description = "Minimum number of vCPUs for OpenShift cluster worker nodes (used when auto-selecting flavor)"
  type        = number
  default     = 16
}

variable "min_worker_memory_gb" {
  description = "Minimum memory in GB for OpenShift cluster worker nodes (used when auto-selecting flavor)"
  type        = number
  default     = 64
}

variable "workers_per_zone" {
  description = "Number of workers per zone"
  type        = number
  default     = 1

  validation {
    condition     = var.workers_per_zone >= 1 && var.workers_per_zone <= 10
    error_message = "workers_per_zone must be between 1 and 10"
  }
}
variable "skip_cluster_health_check" {
  description = "Skip cluster health validation to speed up provisioning (not recommended for production)"
  type        = bool
  default     = true
}
variable "cos_instance_name" {
  description = "Cloud Object Storage instance name for OpenShift registry (defaults to cluster_name-cos)"
  type        = string
  default     = ""
}

variable "create_transit_gateway" {
  description = "Enable creation of Transit Gateway and VPC connections"
  type        = bool
  default     = false
}

variable "transit_gateway_name" {
  description = "Name of the Transit Gateway"
  type        = string
  default     = "tf-tgw"
}

# ============================================================
# GRE Tunnel Variables
# ============================================================

# variable "enable_gre_connections" {
#   description = "Enable GRE redundant connections for on-premises connectivity"
#   type        = bool
#   default     = false
# }

# ============================================================
# Load Balancer Variables
# ============================================================

# variable "enable_load_balancer" {
#   description = "Enable application load balancer creation"
#   type        = bool
#   default     = false
# }

# variable "lb_name" {
#   description = "Name of the application load balancer"
#   type        = string
#   default     = "tf-alb-80"
# }

# variable "lb_is_public" {
#   description = "Whether the load balancer should be public"
#   type        = bool
#   default     = true
# }

# variable "lb_listener_port" {
#   description = "Port for the load balancer listener"
#   type        = number
#   default     = 80
#
#   validation {
#     condition     = var.lb_listener_port > 0 && var.lb_listener_port <= 65535
#     error_message = "lb_listener_port must be between 1 and 65535"
#   }
# }

# variable "lb_listener_protocol" {
#   description = "Protocol for the load balancer listener"
#   type        = string
#   default     = "http"
# }

# variable "lb_pool_name" {
#   description = "Name of the load balancer backend pool"
#   type        = string
#   default     = "tf-pool-80"
# }

# variable "lb_pool_algorithm" {
#   description = "Load balancing algorithm (round_robin, weighted_round_robin, least_connections)"
#   type        = string
#   default     = "round_robin"
#
#   validation {
#     condition     = contains(["round_robin", "weighted_round_robin", "least_connections"], var.lb_pool_algorithm)
#     error_message = "lb_pool_algorithm must be one of: round_robin, weighted_round_robin, least_connections"
#   }
# }

# variable "lb_health_delay" {
#   description = "Health check delay in seconds"
#   type        = number
#   default     = 5
#
#   validation {
#     condition     = var.lb_health_delay >= 2 && var.lb_health_delay <= 60
#     error_message = "lb_health_delay must be between 2 and 60 seconds"
#   }
# }

# variable "lb_health_retries" {
#   description = "Health check max retries"
#   type        = number
#   default     = 2
# }

# variable "lb_health_timeout" {
#   description = "Health check timeout in seconds"
#   type        = number
#   default     = 2
#
#   validation {
#     condition     = var.lb_health_timeout >= 1 && var.lb_health_timeout <= 59
#     error_message = "lb_health_timeout must be between 1 and 59 seconds"
#   }
# }

# GRE Connections Configuration
# variable "gre_connections" {
#   description = "List of redundant GRE connections with 2 tunnels each and BGP configuration"
#   type = list(object({
#     name           = string
#     local_bgp_asn  = number
#     remote_bgp_asn = number
#     tunnels = list(object({
#       name              = string
#       local_gateway_ip  = string
#       remote_gateway_ip = string
#       local_tunnel_ip   = string
#       remote_tunnel_ip  = string
#     }))
#   }))
#   default = [
#     {
#       name           = "gre-connection-1"
#       local_bgp_asn  = 64512
#       remote_bgp_asn = 65001
#       tunnels = [
#         {
#           name              = "gre-connection-1-tunnel1"
#           local_gateway_ip  = "10.10.10.1"
#           remote_gateway_ip = "10.20.20.1"
#           local_tunnel_ip   = "192.168.100.1"
#           remote_tunnel_ip  = "192.168.100.2"
#         },
#         {
#           name              = "gre-connection-1-tunnel2"
#           local_gateway_ip  = "10.10.10.2"
#           remote_gateway_ip = "10.20.20.2"
#           local_tunnel_ip   = "192.168.101.1"
#           remote_tunnel_ip  = "192.168.101.2"
#         }
#       ]
#     },
#     {
#       name           = "gre-connection-2"
#       local_bgp_asn  = 64512
#       remote_bgp_asn = 65001
#       tunnels = [
#         {
#           name              = "gre-connection-2-tunnel1"
#           local_gateway_ip  = "10.10.11.1"
#           remote_gateway_ip = "10.20.21.1"
#           local_tunnel_ip   = "192.168.102.1"
#           remote_tunnel_ip  = "192.168.102.2"
#         },
#         {
#           name              = "gre-connection-2-tunnel2"
#           local_gateway_ip  = "10.10.11.2"
#           remote_gateway_ip = "10.20.21.2"
#           local_tunnel_ip   = "192.168.103.1"
#           remote_tunnel_ip  = "192.168.103.2"
#         }
#       ]
#     },
#     {
#       name           = "gre-connection-3"
#       local_bgp_asn  = 64512
#       remote_bgp_asn = 65001
#       tunnels = [
#         {
#           name              = "gre-connection-3-tunnel1"
#           local_gateway_ip  = "10.10.12.1"
#           remote_gateway_ip = "10.20.22.1"
#           local_tunnel_ip   = "192.168.104.1"
#           remote_tunnel_ip  = "192.168.104.2"
#         },
#         {
#           name              = "gre-connection-3-tunnel2"
#           local_gateway_ip  = "10.10.12.2"
#           remote_gateway_ip = "10.20.22.2"
#           local_tunnel_ip   = "192.168.105.1"
#           remote_tunnel_ip  = "192.168.105.2"
#         }
#       ]
#     }
#   ]
# }

