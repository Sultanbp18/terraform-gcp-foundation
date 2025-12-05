# Service Accounts
resource "google_service_account" "service_accounts" {
  for_each = var.service_accounts

  account_id   = each.value.account_id
  display_name = lookup(each.value, "display_name", each.value.account_id)
  description  = lookup(each.value, "description", null)
  project      = var.project_id
}

# Project IAM Bindings
resource "google_project_iam_member" "project_bindings" {
  for_each = var.project_iam_bindings

  project = var.project_id
  role    = each.value.role
  member  = each.value.member

  dynamic "condition" {
    for_each = lookup(each.value, "condition", null) != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = lookup(condition.value, "description", null)
      expression  = condition.value.expression
    }
  }
}

# Service Account IAM Bindings
resource "google_service_account_iam_member" "sa_bindings" {
  for_each = var.service_account_iam_bindings

  service_account_id = each.value.service_account_id
  role               = each.value.role
  member             = each.value.member

  dynamic "condition" {
    for_each = lookup(each.value, "condition", null) != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = lookup(condition.value, "description", null)
      expression  = condition.value.expression
    }
  }
}

# Custom IAM Roles
resource "google_project_iam_custom_role" "custom_roles" {
  for_each = var.custom_roles

  role_id     = each.value.role_id
  title       = each.value.title
  description = lookup(each.value, "description", null)
  permissions = each.value.permissions
  project     = var.project_id
  stage       = lookup(each.value, "stage", "GA")
}

# Workload Identity Binding for GKE
resource "google_service_account_iam_member" "workload_identity" {
  for_each = var.workload_identity_bindings

  service_account_id = each.value.service_account_id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${each.value.namespace}/${each.value.ksa_name}]"
}

# Service Account Keys (use sparingly, prefer Workload Identity)
resource "google_service_account_key" "keys" {
  for_each = var.service_account_keys

  service_account_id = each.value.service_account_id
  key_algorithm      = lookup(each.value, "key_algorithm", "KEY_ALG_RSA_2048")
  public_key_type    = lookup(each.value, "public_key_type", "TYPE_X509_PEM_FILE")
}