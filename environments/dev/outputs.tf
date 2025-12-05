# Networking
output "network_id" {
  description = "The ID of the VPC network"
  value       = module.networking.network_id
}

output "network_self_link" {
  description = "The self-link of the VPC network"
  value       = module.networking.network_self_link
}

output "subnets" {
  description = "Map of subnet details"
  value       = module.networking.subnets
}

# Compute
output "compute_instances" {
  description = "Map of compute instance details"
  value       = module.compute.instances
}

# Storage
output "storage_buckets" {
  description = "Map of storage bucket details"
  value       = module.storage.buckets
}

# IAM
output "service_accounts" {
  description = "Created service accounts"
  value       = module.iam.service_accounts
}

output "service_account_emails" {
  description = "Service account emails"
  value       = module.iam.service_account_emails
}

# GKE - Uncomment when cluster is deployed
# output "gke_cluster_name" {
#   value = module.gke_private.cluster_name
# }
# 
# output "gke_cluster_endpoint" {
#   value     = module.gke_private.cluster_endpoint
#   sensitive = true
# }
# 
# output "gke_cluster_ca_certificate" {
#   value     = module.gke_private.cluster_ca_certificate
#   sensitive = true
# }