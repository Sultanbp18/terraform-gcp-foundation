# GKE Private Cluster Module

Creates a production-ready private Google Kubernetes Engine (GKE) cluster with enhanced security features, Workload Identity, and flexible node pool configurations.

## Features

- **Private Cluster Configuration** - Control plane and nodes isolated from public internet
- **Workload Identity** - Secure authentication for GKE workloads to GCP services
- **VPC-Native Networking** - Alias IP ranges for pods and services
- **Multiple Node Pools** - Support for diverse workload requirements
- **Auto-scaling** - Cluster and node pool autoscaling capabilities
- **Security Hardening** - Shielded nodes, network policies, binary authorization
- **Managed Updates** - Automated node repairs and upgrades
- **Flexible Configuration** - Customizable for dev, staging, and production environments

## Why Private Cluster?

**Private clusters should be your default choice for:**
- Production workloads
- Sensitive data processing
- Compliance requirements (PCI-DSS, HIPAA, SOC 2)
- Internal services and APIs
- Cost optimization (reduced NAT egress)

**Key Security Benefits:**
- ✓ Nodes have no public IP addresses
- ✓ Control plane accessible only from authorized networks
- ✓ Reduced attack surface
- ✓ Network-level isolation
- ✓ Enforced through infrastructure code

## Usage

### Minimal Configuration

```hcl
module "gke_private" {
  source = "../../modules/gke-private"

  project_id   = "my-project-id"
  cluster_name = "dev-private-cluster"
  location     = "asia-southeast2"

  network    = "projects/my-project-id/global/networks/my-vpc"
  subnetwork = "projects/my-project-id/regions/asia-southeast2/subnetworks/my-subnet"

  # Secondary IP ranges for VPC-native cluster
  pods_secondary_range_name     = "pods"
  services_secondary_range_name = "services"

  # Node pools
  node_pools = {
    default = {
      name               = "default-pool"
      machine_type       = "e2-medium"
      initial_node_count = 1
      autoscaling = {
        min_node_count = 1
        max_node_count = 3
      }
    }
  }
}
```

### Production Configuration

```hcl
module "gke_private" {
  source = "../../modules/gke-private"

  project_id   = "my-prod-project"
  cluster_name = "prod-private-cluster"
  location     = "asia-southeast2"

  network    = module.networking.network_self_link
  subnetwork = module.networking.subnets["gke-subnet"].self_link

  # Secondary IP ranges
  pods_secondary_range_name     = "pods-range"
  services_secondary_range_name = "services-range"

  # Private cluster configuration
  master_ipv4_cidr_block  = "172.16.0.0/28"
  enable_private_endpoint = false
  master_global_access_enabled = true

  # Master authorized networks - restrict access
  master_authorized_networks = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "Internal VPC"
    },
    {
      cidr_block   = "203.0.113.0/24"
      display_name = "Office Network"
    }
  ]

  # Kubernetes version
  kubernetes_version = "1.28"
  release_channel    = "REGULAR"

  # Security features
  enable_shielded_nodes       = true
  enable_binary_authorization = true
  network_policy              = true

  # Node pools
  node_pools = {
    general = {
      name               = "general-pool"
      machine_type       = "e2-standard-4"
      initial_node_count = 2
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      
      autoscaling = {
        min_node_count = 2
        max_node_count = 10
      }
      
      auto_repair  = true
      auto_upgrade = true
      
      labels = {
        workload_type = "general"
      }
    }
    
    compute-intensive = {
      name               = "compute-pool"
      machine_type       = "c2-standard-8"
      initial_node_count = 0
      
      autoscaling = {
        min_node_count = 0
        max_node_count = 5
      }
      
      labels = {
        workload_type = "compute"
      }
      
      taints = [{
        key    = "workload"
        value  = "compute"
        effect = "NO_SCHEDULE"
      }]
    }
    
    spot-pool = {
      name               = "spot-pool"
      machine_type       = "e2-standard-4"
      initial_node_count = 0
      spot               = true
      
      autoscaling = {
        min_node_count = 0
        max_node_count = 10
      }
      
      labels = {
        workload_type = "batch"
      }
      
      taints = [{
        key    = "workload"
        value  = "batch"
        effect = "NO_SCHEDULE"
      }]
    }
  }

  # Maintenance window
  maintenance_window = {
    start_time = "03:00"
  }

  # Labels
  labels = {
    environment = "production"
    managed_by  = "terraform"
    cost_center = "engineering"
  }
}
```

### With Workload Identity

```hcl
# Create service account for workload
module "iam" {
  source = "../../modules/iam"

  project_id = "my-project-id"

  service_accounts = {
    gke-app = {
      account_id   = "gke-app-sa"
      display_name = "GKE App Service Account"
    }
  }

  workload_identity_bindings = {
    app-backend = {
      service_account_id = "projects/my-project-id/serviceAccounts/gke-app-sa@my-project-id.iam.gserviceaccount.com"
      namespace          = "default"
      ksa_name           = "app-backend-ksa"
    }
  }

  project_iam_bindings = {
    storage-access = {
      role   = "roles/storage.objectViewer"
      member = "serviceAccount:gke-app-sa@my-project-id.iam.gserviceaccount.com"
    }
  }
}

# Create GKE cluster
module "gke_private" {
  source = "../../modules/gke-private"

  project_id   = "my-project-id"
  cluster_name = "app-cluster"
  location     = "asia-southeast2"

  network                       = module.networking.network_self_link
  subnetwork                    = module.networking.subnets["gke-subnet"].self_link
  pods_secondary_range_name     = "pods"
  services_secondary_range_name = "services"

  node_pools = {
    default = {
      name               = "default-pool"
      machine_type       = "e2-medium"
      service_account    = module.iam.service_account_emails["gke-app"]
      initial_node_count = 1
      autoscaling = {
        min_node_count = 1
        max_node_count = 5
      }
    }
  }
}
```

### Multi-Zone Regional Cluster

```hcl
module "gke_private" {
  source = "../../modules/gke-private"

  project_id   = "my-project-id"
  cluster_name = "regional-cluster"
  location     = "asia-southeast2" # Regional cluster

  network                       = module.networking.network_self_link
  subnetwork                    = module.networking.subnets["gke-subnet"].self_link
  pods_secondary_range_name     = "pods"
  services_secondary_range_name = "services"

  node_pools = {
    primary = {
      name               = "primary-pool"
      machine_type       = "e2-standard-4"
      initial_node_count = 1 # Per zone (3 zones = 3 nodes total)
      
      autoscaling = {
        min_node_count  = 1  # Per zone
        max_node_count  = 5  # Per zone
        location_policy = "BALANCED" # Distribute across zones
      }
      
      auto_repair  = true
      auto_upgrade = true
    }
  }

  labels = {
    environment = "production"
    ha_enabled  = "true"
  }
}
```

## Network Requirements

### VPC Subnet Configuration

Your subnet must have secondary IP ranges configured for pods and services:

```hcl
resource "google_compute_subnetwork" "gke_subnet" {
  name          = "gke-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = "asia-southeast2"
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/20"
  }

  private_ip_google_access = true
}
```

### IP Range Sizing Guide

| Cluster Size | Nodes | Pods/Node | Pods Range | Services Range |
|--------------|-------|-----------|------------|----------------|
| Small        | 1-10  | 110       | /20 (4K)   | /24 (256)      |
| Medium       | 11-50 | 110       | /16 (64K)  | /20 (4K)       |
| Large        | 51+   | 110       | /14 (256K) | /18 (16K)      |

### Cloud NAT Configuration

Private nodes require Cloud NAT for internet access:

```hcl
module "networking" {
  source = "../../modules/networking"
  
  # ... other configuration ...
  
  create_nat = true
  nat_region = "asia-southeast2"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_id | The GCP project ID | `string` | n/a | yes |
| cluster_name | The name of the GKE cluster | `string` | n/a | yes |
| location | The location (region or zone) of the cluster | `string` | n/a | yes |
| network | The VPC network to host the cluster | `string` | n/a | yes |
| subnetwork | The subnetwork to host the cluster | `string` | n/a | yes |
| pods_secondary_range_name | The name of the secondary range for pods | `string` | n/a | yes |
| services_secondary_range_name | The name of the secondary range for services | `string` | n/a | yes |
| master_ipv4_cidr_block | The IP range in CIDR notation for the master network | `string` | `"172.16.0.0/28"` | no |
| enable_private_endpoint | Whether the master's internal IP address is used as the cluster endpoint | `bool` | `false` | no |
| master_global_access_enabled | Whether master could be accessed globally | `bool` | `false` | no |
| master_authorized_networks | List of master authorized networks | `list(object)` | `[]` | no |
| kubernetes_version | The Kubernetes version for the master and nodes | `string` | `null` | no |
| release_channel | The release channel of this cluster | `string` | `"REGULAR"` | no |
| node_pools | Map of node pool configurations | `map(object)` | `{}` | no |
| enable_shielded_nodes | Enable Shielded GKE Nodes | `bool` | `true` | no |
| network_policy | Enable Network Policy addon | `bool` | `true` | no |
| enable_binary_authorization | Enable Binary Authorization | `bool` | `false` | no |
| labels | Labels to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the cluster |
| cluster_name | The name of the cluster |
| cluster_endpoint | The IP address of the cluster master (sensitive) |
| cluster_ca_certificate | The cluster CA certificate (sensitive) |
| workload_identity_pool | The workload identity pool for the cluster |
| node_pools | Map of node pool details |
| master_version | The current version of the master |

## Post-Deployment Steps

### 1. Configure kubectl

```bash
gcloud container clusters get-credentials <cluster-name> \
  --region <region> \
  --project <project-id>
```

### 2. Create Kubernetes Service Account with Workload Identity

```bash
kubectl create serviceaccount app-backend-ksa -n default

kubectl annotate serviceaccount app-backend-ksa \
  iam.gke.io/gcp-service-account=gke-app-sa@PROJECT_ID.iam.gserviceaccount.com
```

### 3. Verify Workload Identity

```bash
kubectl run -it --rm --restart=Never --image=google/cloud-sdk:slim \
  --serviceaccount=app-backend-ksa workload-identity-test \
  -- gcloud auth list
```

## Best Practices

### Security

1. **Always enable private nodes** - This module enforces private nodes by default
2. **Restrict master access** - Use `master_authorized_networks` to limit control plane access
3. **Enable Shielded Nodes** - Protects against rootkits and bootkits
4. **Use Workload Identity** - Avoid service account keys in pods
5. **Enable Binary Authorization** - Enforce deployment policy and image signing
6. **Enable Network Policies** - Implement pod-to-pod network segmentation

### High Availability

1. **Use regional clusters** - Set `location` to a region (not zone)
2. **Multiple node pools** - Separate workload types
3. **Configure autoscaling** - Handle traffic spikes automatically
4. **Set PodDisruptionBudgets** - Ensure minimum replicas during updates
5. **Schedule maintenance windows** - Control when updates occur

### Cost Optimization

1. **Use Spot/Preemptible nodes** - For fault-tolerant workloads
2. **Right-size node pools** - Match machine types to workload requirements
3. **Enable cluster autoscaling** - Scale down during low usage
4. **Use committed use discounts** - For predictable workloads
5. **Monitor resource utilization** - Identify optimization opportunities

### Operations

1. **Enable automatic repairs** - Self-healing nodes
2. **Enable automatic upgrades** - Stay current with security patches
3. **Use release channels** - Managed Kubernetes version updates
4. **Configure logging and monitoring** - Use Cloud Logging and Monitoring
5. **Tag resources** - Use labels for cost allocation and organization

## Troubleshooting

### Cannot connect to cluster

```bash
# Verify you're in an authorized network
gcloud container clusters describe <cluster-name> \
  --region <region> \
  --format="get(masterAuthorizedNetworksConfig)"

# For private endpoint clusters, connect from within VPC
# Use a bastion host or Cloud Shell (if authorized)
```

### Nodes can't pull images

```bash
# Verify Cloud NAT is configured
gcloud compute routers nats list --router=<router-name> --region=<region>

# Check service account permissions
gcloud projects get-iam-policy <project-id> \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:<sa-email>"
```

### Workload Identity not working

```bash
# Verify IAM binding exists
gcloud iam service-accounts get-iam-policy <gsa-email>

# Check KSA annotation
kubectl get serviceaccount <ksa-name> -o yaml
```

## Migration from Public to Private

1. Create new private cluster with this module
2. Set up Workload Identity for all workloads
3. Deploy workloads to private cluster
4. Test thoroughly
5. Migrate traffic using DNS or load balancer
6. Decommission old cluster

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| google | >= 5.0.0 |
| google-beta | >= 5.0.0 |

## Related Modules

- [IAM Module](../iam/README.md) - Service accounts and Workload Identity
- [Networking Module](../networking/README.md) - VPC with secondary ranges
- [GKE Public Module](../gke-public/README.md) - Public clusters (limited use cases)

## Examples

See the [examples directory](../../examples/gke-private/) for complete, runnable examples.

## Support

For issues or questions, please refer to the main project documentation or open an issue in the repository.