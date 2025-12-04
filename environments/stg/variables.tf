variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
  default     = "asia-southeast2"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
}