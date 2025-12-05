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
│   ├── storage/       # GCS buckets
│   ├── iam/           # Service accounts and IAM bindings
│   ├── gke-private/   # Private GKE clusters (production)
│   └── gke-public/    # Public GKE clusters (limited use)
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

### IAM Module

Manages service accounts, IAM bindings, custom roles, and Workload Identity for GKE.

**Example:**
```hcl
module "iam" {
  source = "../../modules/iam"
  
  project_id = "my-project"
  
  service_accounts = {
    gke-app = {
      account_id   = "gke-app-sa"
      display_name = "GKE Application Service Account"
    }
  }
  
  workload_identity_bindings = {
    app = {
      service_account_id = "projects/my-project/serviceAccounts/gke-app-sa@my-project.iam.gserviceaccount.com"
      namespace          = "default"
      ksa_name           = "app-ksa"
    }
  }
}
```

[Full documentation](modules/iam/README.md)

### GKE Private Cluster Module

Creates production-ready private GKE clusters with enhanced security and Workload Identity.

**Example:**
```hcl
module "gke_private" {
  source = "../../modules/gke-private"
  
  project_id   = "my-project"
  cluster_name = "prod-private-cluster"
  location     = "asia-southeast2"
  
  network    = module.networking.network_self_link
  subnetwork = module.networking.subnets["gke-subnet"].self_link
  
  pods_secondary_range_name     = "pods"
  services_secondary_range_name = "services"
  
  node_pools = {
    default = {
      name         = "default-pool"
      machine_type = "e2-standard-4"
      autoscaling = {
        min_node_count = 1
        max_node_count = 5
      }
    }
  }
}
```

[Full documentation](modules/gke-private/README.md)

### GKE Public Cluster Module

⚠️ **For development/testing only.** Creates public GKE clusters with nodes accessible from the internet.

**Example:**
```hcl
module "gke_public" {
  source = "../../modules/gke-public"
  
  project_id   = "my-dev-project"
  cluster_name = "dev-public-cluster"
  location     = "asia-southeast2"
  
  network    = module.networking.network_self_link
  subnetwork = module.networking.subnets["gke-subnet"].self_link
  
  pods_secondary_range_name     = "pods"
  services_secondary_range_name = "services"
  
  master_authorized_networks = [
    {
      cidr_block   = "203.0.113.0/24"
      display_name = "Office Network"
    }
  ]
  
  node_pools = {
    default = {
      name         = "default-pool"
      machine_type = "e2-medium"
      autoscaling = {
        min_node_count = 1
        max_node_count = 3
      }
    }
  }
}
```

[Full documentation](modules/gke-public/README.md)

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
# Core APIs
gcloud services enable compute.googleapis.com
gcloud services enable storage-api.googleapis.com
gcloud services enable cloudkms.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com

# For GKE and IAM modules
gcloud services enable container.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable logging.googleapis.com
gcloud services enable monitoring.googleapis.com
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
