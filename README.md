# GCP Terraform Foundation

A production-ready Terraform infrastructure foundation for Google Cloud Platform with reusable modules and multi-environment support.

## Project Structure

```
terraform-gcp-foundation/
├── bootstrap/           # Initial state backend setup
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── modules/            # Reusable infrastructure modules
│   ├── networking/    # VPC, subnets, firewall, NAT
│   ├── compute/       # GCE instances and groups
│   └── storage/       # GCS buckets
└── environments/      # Environment-specific configs
    ├── dev/          # Development
    ├── staging/      # Staging
    └── prod/         # Production
```

## Quick Start

### 1. Bootstrap Remote State

First, set up the remote state backend:

```bash
cd bootstrap
terraform init
terraform plan
terraform apply
```

After successful apply, uncomment the backend configuration in each environment's `versions.tf` and run `terraform init -migrate-state`.

### 2. Deploy an Environment

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

## Modules

### Networking Module

Creates VPC networks with subnets, firewall rules, and Cloud NAT.

**Example:**
```hcl
module "networking" {
  source = "../../modules/networking"
  
  project_id   = "my-project"
  network_name = "my-vpc"
  
  subnets = {
    subnet1 = {
      subnet_name   = "subnet-01"
      subnet_ip     = "10.0.1.0/24"
      subnet_region = "asia-southeast2"
    }
  }
}
```

[Full documentation](modules/networking/README.md)

### Compute Module

Manages GCE instances and instance groups.

**Example:**
```hcl
module "compute" {
  source = "../../modules/compute"
  
  project_id = "my-project"
  network    = module.networking.network_self_link
  
  instances = {
    web = {
      name         = "web-01"
      machine_type = "e2-micro"
      zone         = "asia-southeast2-a"
    }
  }
}
```

[Full documentation](modules/compute/README.md)

### Storage Module

Creates and manages GCS buckets with lifecycle rules and IAM.

**Example:**
```hcl
module "storage" {
  source = "../../modules/storage"
  
  project_id = "my-project"
  
  buckets = {
    data = {
      name     = "my-data-bucket"
      location = "asia-southeast2"
    }
  }
}
```

[Full documentation](modules/storage/README.md)

## Environments

Each environment (dev, staging, prod) has its own:
- Isolated state file
- Customizable variables
- Independent infrastructure

### Environment Configuration

1. Copy the example vars file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Update `terraform.tfvars`:
```hcl
project_id  = "your-project-id"
region      = "asia-southeast2"
environment = "dev"
```

3. Deploy:
```bash
terraform init
terraform apply
```

## Best Practices

- **State Management**: Always use remote state for team collaboration
- **Workspaces**: Each environment uses separate state files via prefixes
- **Modules**: Keep modules generic and reusable
- **Variables**: Use `.tfvars` files for environment-specific values
- **Secrets**: Never commit `.tfvars` files or credentials to git

## Prerequisites

- Terraform >= 1.5.0
- GCP account with appropriate permissions
- `gcloud` CLI authenticated

## Required GCP APIs

Enable these APIs before deploying:

```bash
gcloud services enable compute.googleapis.com
gcloud services enable storage-api.googleapis.com
gcloud services enable cloudkms.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

## Usage Examples

### Create a Simple Dev Environment

```hcl
# environments/dev/terraform.tfvars
project_id  = "my-dev-project"
region      = "asia-southeast2"

instances = {
  app = {
    name         = "dev-app-server"
    machine_type = "e2-micro"
    zone         = "asia-southeast2-a"
    tags         = ["http-server"]
  }
}

buckets = {
  logs = {
    name     = "dev-logs-bucket-12345"
    location = "asia-southeast2"
  }
}
```

### Production Setup with Multiple Instances

```hcl
# environments/prod/terraform.tfvars
project_id  = "my-prod-project"
region      = "asia-southeast2"

instances = {
  web1 = {
    name         = "prod-web-01"
    machine_type = "e2-medium"
    zone         = "asia-southeast2-a"
    tags         = ["http-server", "https-server"]
  }
  web2 = {
    name         = "prod-web-02"
    machine_type = "e2-medium"
    zone         = "asia-southeast2-b"
    tags         = ["http-server", "https-server"]
  }
}
```

## Troubleshooting

### State Lock Issues
```bash
terraform force-unlock <lock-id>
```

### Re-initialize Backend
```bash
terraform init -reconfigure
```

### Import Existing Resources
```bash
terraform import 'module.compute.google_compute_instance.instances["web"]' projects/PROJECT/zones/ZONE/instances/INSTANCE
```

## Contributing

This is a portfolio project demonstrating GCP infrastructure as code best practices.

## License

MIT License - Free to use for your own projects.
