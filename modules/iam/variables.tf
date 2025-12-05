variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "service_accounts" {
  description = "Map of service accounts to create"
  type = map(object({
    account_id   = string
    display_name = optional(string)
    description  = optional(string)
  }))
  default = {}
}

variable "project_iam_bindings" {
  description = "Map of project-level IAM bindings"
  type = map(object({
    role   = string
    member = string
    condition = optional(object({
      title       = string
      description = optional(string)
      expression  = string
    }))
  }))
  default = {}
}

variable "service_account_iam_bindings" {
  description = "Map of service account IAM bindings"
  type = map(object({
    service_account_id = string
    role               = string
    member             = string
    condition = optional(object({
      title       = string
      description = optional(string)
      expression  = string
    }))
  }))
  default = {}
}

variable "custom_roles" {
  description = "Map of custom IAM roles to create"
  type = map(object({
    role_id     = string
    title       = string
    description = optional(string)
    permissions = list(string)
    stage       = optional(string)
  }))
  default = {}
}

variable "workload_identity_bindings" {
  description = "Map of Workload Identity bindings for GKE"
  type = map(object({
    service_account_id = string
    namespace          = string
    ksa_name           = string
  }))
  default = {}
}

variable "service_account_keys" {
  description = "Map of service account keys to create (use sparingly, prefer Workload Identity)"
  type = map(object({
    service_account_id = string
    key_algorithm      = optional(string)
    public_key_type    = optional(string)
  }))
  default = {}
}