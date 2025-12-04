# Storage Module

Creates GCS buckets with lifecycle rules, versioning, and IAM permissions.

## Features

- Multiple storage buckets
- Versioning support
- KMS encryption
- Lifecycle management
- CORS configuration
- IAM access control

## Usage

```hcl
module "storage" {
  source = "../../modules/storage"

  project_id = "my-project"
  
  buckets = {
    app-data = {
      name               = "my-app-data-bucket"
      location           = "asia-southeast2"
      storage_class      = "STANDARD"
      versioning_enabled = true
      lifecycle_rules = [{
        action = {
          type = "Delete"
        }
        condition = {
          age = 30
        }
      }]
    }
  }
  
  bucket_iam_members = {
    viewer = {
      bucket_key = "app-data"
      role       = "roles/storage.objectViewer"
      member     = "user:someone@example.com"
    }
  }
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project_id | GCP project ID | string | required |
| buckets | Bucket configurations | map | {} |
| bucket_iam_members | IAM member bindings | map | {} |

## Outputs

| Name | Description |
|------|-------------|
| buckets | Map of bucket details |
| bucket_urls | Map of bucket URLs |