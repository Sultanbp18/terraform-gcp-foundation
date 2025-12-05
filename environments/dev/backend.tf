# Uncomment after bootstrap is complete
terraform {
    backend "gcs" {
        bucket = "sultan-tfstate" # replace with your preferred project ID
        prefix = "environments/dev"
    }
}