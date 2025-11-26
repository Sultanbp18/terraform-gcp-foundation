# Terraform Bootstrap

Bootstrap configuration for GCP Terraform state management.

## What it does

- Creates a GCS bucket for storing terraform state
- Sets up KMS encryption for the bucket
- Configures proper IAM permissions

## Usage

1. Make sure you have `gcloud` authenticated:
```bash
gcloud auth application-default login
```

2. Enable required APIs:
```bash
gcloud services enable cloudkms.googleapis.com
gcloud services enable storage-api.googleapis.com
```

3. Update `project_id` in `variables.tf` or create a `terraform.tfvars`:
```hcl
project_id  = "your-project-id"
bucket_name = "tfstate-your-project"
```

4. Run terraform:
```bash
terraform init
terraform plan
terraform apply
```

5. After first apply, you can migrate to remote state:
- Uncomment the backend config in `backend.tf`
- Update the bucket name to match your bucket
- Run `terraform init -migrate-state`

## Files

- `main.tf` - Main resources (bucket, KMS, IAM)
- `variables.tf` - Input variables
- `versions.tf` - Provider configuration
- `outputs.tf` - Output values
- `backend.tf` - Backend config (commented initially)

## Notes

- The bucket name must be globally unique across all GCP
- Keep `prevent_destroy = false` for testing, change to `true` in production
- KMS key rotates every 90 days
- State versioning is enabled automatically