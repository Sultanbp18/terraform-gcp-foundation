variable "project_id" {
  type        = string
  description = "The project ID to deploy resources"
}

variable "buckets" {
  type = map(object({
    name                        = string
    location                    = string
    storage_class               = optional(string)
    force_destroy               = optional(bool)
    uniform_bucket_level_access = optional(bool)
    versioning_enabled          = optional(bool)
    encryption_key              = optional(string)
    labels                      = optional(map(string))
    lifecycle_rules = optional(list(object({
      action = object({
        type          = string
        storage_class = optional(string)
      })
      condition = object({
        age                   = optional(number)
        matches_storage_class = optional(list(string))
        num_newer_versions    = optional(number)
      })
    })), [])
    cors = optional(list(object({
      origin          = optional(list(string))
      method          = optional(list(string))
      response_header = optional(list(string))
      max_age_seconds = optional(number)
    })), [])
  }))
  description = "Map of storage buckets to create"
  default     = {}
}

variable "bucket_iam_members" {
  type = map(object({
    bucket_key = string
    role       = string
    member     = string
  }))
  description = "IAM members to add to buckets"
  default     = {}
}

variable "labels" {
  type        = map(string)
  description = "Default labels to apply to all buckets"
  default     = {}
}