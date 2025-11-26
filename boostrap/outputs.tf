output "bucket_name" {
  value = google_storage_bucket.terraform_state.name
}

output "kms_key_id" {
  value = google_kms_crypto_key.terraform_state.id
}

output "project_id" {
  value = var.project_id
}