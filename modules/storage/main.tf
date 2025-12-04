resource "google_storage_bucket" "buckets" {
  for_each = var.buckets

  name          = each.value.name
  location      = each.value.location
  project       = var.project_id
  storage_class = lookup(each.value, "storage_class", "STANDARD")
  force_destroy = lookup(each.value, "force_destroy", false)

  uniform_bucket_level_access = lookup(each.value, "uniform_bucket_level_access", true)

  dynamic "versioning" {
    for_each = lookup(each.value, "versioning_enabled", false) ? [1] : []
    content {
      enabled = true
    }
  }

  dynamic "encryption" {
    for_each = lookup(each.value, "encryption_key", null) != null ? [1] : []
    content {
      default_kms_key_name = each.value.encryption_key
    }
  }

  dynamic "lifecycle_rule" {
    for_each = each.value.lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lookup(lifecycle_rule.value.action, "storage_class", null)
      }
      condition {
        age                   = lookup(lifecycle_rule.value.condition, "age", null)
        matches_storage_class = lookup(lifecycle_rule.value.condition, "matches_storage_class", null)
        num_newer_versions    = lookup(lifecycle_rule.value.condition, "num_newer_versions", null)
      }
    }
  }

  dynamic "cors" {
    for_each = each.value.cors
    content {
      origin          = lookup(cors.value, "origin", [])
      method          = lookup(cors.value, "method", [])
      response_header = lookup(cors.value, "response_header", [])
      max_age_seconds = lookup(cors.value, "max_age_seconds", 3600)
    }
  }

  labels = merge(var.labels, lookup(each.value, "labels", {}))
}

resource "google_storage_bucket_iam_member" "members" {
  for_each = var.bucket_iam_members

  bucket = google_storage_bucket.buckets[each.value.bucket_key].name
  role   = each.value.role
  member = each.value.member
}