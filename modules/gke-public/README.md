# GKE Public Cluster Module

⚠️ **SECURITY WARNING**: This module creates a GKE cluster with public nodes. Use only for specific scenarios where public access is required. For production workloads, use the [GKE Private Module](../gke-private/README.md) instead.

## When to Use This Module

### ✅ Appropriate Use Cases
- Development/Testing environments requiring direct internet access
- Public-facing APIs that need to accept traffic directly from the internet
- Demonstration/Sandbox clusters for learning and experimentation
- Legacy application migration with gradual transition to private clusters

### ❌ Do NOT Use For
- Production workloads
- Sensitive data processing
- Compliance-regulated environments (PCI-DSS, HIPAA, SOC 2)
- Internal services and APIs

## Security Considerations

**Before using this module, understand these security implications:**
1. Nodes have public IP addresses - Directly accessible from the internet
2. Larger attack surface - More exposure to potential threats
3. Requires additional hardening - Firewall rules, security groups, etc.
4. Higher egress costs - Traffic to internet not optimized through NAT

**Required Security Measures:**
- Configure `master_authorized_networks` to restrict control plane access
- Implement strict firewall rules
- Enable network policies and binary authorization
- Regular security audits

## Usage

### Basic Configuration

```hcl
module "gke_public" {
  source = "../../modules/gke-public"

  project_id   = "my-dev-project"
  cluster_name = "dev-public-cluster"
  location     = "asia-southeast2"

  network    = "projects/my-dev-project/global/networks/my-vpc"
  subnetwork = "projects/my-dev-project/regions/asia-southeast2/subnetworks/my-subnet"

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

### With Security Hardening

```hcl
module "gke_public" {
  source = "../../modules/gke-public"

  project_id   = "my-project"
  cluster_name = "demo-public-cluster"
  location     = "asia-southeast2"

  network    = module.networking.network_self_link
  subnetwork = module.networking.subnets["gke-subnet"].self_link

  pods_secondary_range_name     = "pods-range"
  services_secondary_range_name = "services-range"

  master_authorized_networks = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "Internal Network"
    }
  ]

  enable_shielded_nodes       = true
  enable_binary_authorization = false
  network_policy              = true

  kubernetes_version = "1.28"
  release_channel    = "REGULAR"

  node_pools = {
    general = {
      name               = "general-pool"
      machine_type       = "e2-standard-4"
      initial_node_count = 2
      autoscaling = {
        min_node_count = 1
        max_node_count = 5
      }
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  labels = {
    environment = "demo"
    managed_by  = "terraform"
  }
}
```

## Network Requirements

### VPC Subnet with Secondary Ranges

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

### Firewall Rules

```hcl
resource "google_compute_firewall" "gke_ingress" {
  name    = "gke-public-ingress"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443", "80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gke-public-node"]
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
| master_authorized_networks | List of master authorized networks | `list(object)` | `[]` | no |
| node_pools | Map of node pool configurations | `map(object)` | `{}` | no |
| enable_shielded_nodes | Enable Shielded GKE Nodes | `bool` | `true` | no |
| network_policy | Enable Network Policy addon | `bool` | `true` | no |

See [variables.tf](./variables.tf) for complete list of inputs.

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the cluster |
| cluster_name | The name of the cluster |
| cluster_endpoint | The IP address of the cluster master (sensitive) |
| workload_identity_pool | The workload identity pool for the cluster |
| node_pools | Map of node pool details |

See [outputs.tf](./outputs.tf) for complete list of outputs.

## Comparison: Public vs Private Clusters

| Aspect | Public Cluster | Private Cluster |
|--------|---------------|-----------------|
| Security | ❌ Lower | ✅ Higher |
| Compliance | ❌ Limited | ✅ Full support |
| Attack Surface | ❌ Larger | ✅ Minimal |
| Egress Costs | ❌ Higher | ✅ Lower |
| Setup Complexity | ✅ Simpler | ⚠️ Requires NAT |
| **Recommendation** | Dev/Testing only | **Production default** |

## Migration to Private Cluster

When ready to migrate to a private cluster:

1. Create private cluster using [gke-private module](../gke-private/README.md)
2. Deploy workloads to both clusters
3. Test thoroughly in private cluster
4. Migrate traffic gradually
5. Decommission public cluster

## Best Practices

### Security
- Always configure `master_authorized_networks`
- Implement strict firewall rules
- Enable shielded nodes and network policies
- Use Workload Identity instead of service account keys
- Regular security audits

### Operations
- Use regional clusters for high availability
- Configure autoscaling for traffic variations
- Set maintenance windows for controlled updates
- Monitor resource usage and costs

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| google | >= 5.0.0 |

## Related Modules

- [GKE Private Module](../gke-private/README.md) - Recommended for production
- [IAM Module](../iam/README.md) - Service accounts and Workload Identity
- [Networking Module](../networking/README.md) - VPC with secondary ranges