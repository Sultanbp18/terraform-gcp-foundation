# Compute Module

Creates Google Compute Engine instances with configurable networking and tags.

## Features

- Multiple VM instances with custom configurations
- Flexible networking (VPC, subnet, external IP)
- Instance tagging for firewall rules
- Support for different machine types and zones

## Usage

```hcl
module "compute" {
  source = "../../modules/compute"

  project_id = var.project_id
  network    = module.networking.network_self_link

  instances = {
    web-01 = {
      name                = "dev-web-01"
      machine_type        = "e2-micro"
      zone                = "asia-southeast2-a"
      subnetwork          = module.networking.subnets["subnet-01"].self_link
      tags                = ["ssh", "http-server"]
      enable_external_ip  = true
    }
  }
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project_id | GCP project ID | string | required |
| network | VPC network self-link | string | required |
| instances | Instance configurations | map | {} |

## Outputs

| Name | Description |
|------|-------------|
| instances | Map of instance details |