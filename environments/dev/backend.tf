# Uncomment after bootstrap is complete
terraform {
    backend "gcs" {
        bucket = "your-project-id" # replace with your preferred project ID
        prefix = "environments/dev"
    }
}