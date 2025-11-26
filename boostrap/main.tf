data "google_project" "current" {
}

data "google_storage_project_service_account" "gcs_account" {
  project = var.project_id
}

resource "random_id" "bucket_prefix" {
  byte_length = 8
}

# KMS for bucket encryption
resource "google_kms_key_ring" "terraform_state" {
  name     = "${random_id.bucket_prefix.hex}-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "terraform_state" {
  name            = "terraform-state-key"
  key_ring        = google_kms_key_ring.terraform_state.id
  rotation_period = "7776000s"

  lifecycle {
    prevent_destroy = false
  }
}

# Grant GCS service account permission to use KMS key
resource "google_project_iam_member" "gcs_kms" {
  project = var.project_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member  = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}

# Terraform state bucket
resource "google_storage_bucket" "terraform_state" {
  name                        = var.bucket_name
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  force_destroy               = false

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.terraform_state.id
  }

  depends_on = [google_project_iam_member.gcs_kms]
}