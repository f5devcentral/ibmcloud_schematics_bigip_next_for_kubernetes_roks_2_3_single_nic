# License Module Variables

variable "enabled" {
  description = "Enable License CR deployment"
  type        = bool
  default     = true
}

variable "utils_namespace" {
  description = "Namespace for F5 utility components (where License CR will be deployed)"
  type        = string
  default     = "f5-utils"
}

variable "jwt_token" {
  description = "JWT token for F5 license authentication"
  type        = string
  sensitive   = true
}

variable "license_mode" {
  description = "License operation mode (connected or disconnected)"
  type        = string
  default     = "connected"

  validation {
    condition     = contains(["connected", "disconnected"], var.license_mode)
    error_message = "license_mode must be either 'connected' or 'disconnected'."
  }
}

variable "cneinstance_dependency" {
  description = "Explicit dependency on CNEInstance deployment (ensures License CRD is available)"
  type        = any
  default     = null
}
