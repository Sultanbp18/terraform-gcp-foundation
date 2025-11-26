variable "project_id" {
  type        = string
  description = "GCP project ID"
  default     = "your-project-id" # replace with your preferred project ID
}

variable "region" {
  type        = string
  description = "GCP region"
  default     = "asia-southeast2" # replace with your preferred region
}

variable "zone" {
  type        = string
  description = "GCP zone"
  default     = "asia-southeast2-a" # replace with your preferred zone
}

variable "bucket_name" {
  type        = string
  description = "Name for the terraform state bucket"
  default     = "tfstate-unique-name" # replace with your preferred bucket name
}
