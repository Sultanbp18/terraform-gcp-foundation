# Networking Module

Creates a VPC network with subnets, firewall rules, and optional Cloud NAT.

## Features

- Custom VPC network
- Multiple subnets with secondary IP ranges
- Flexible firewall rules
- Optional Cloud NAT for private instances

## Usage

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
  
  firewall_rules = {
    allow_ssh = {
      name          = "allow-ssh"
      source_ranges = ["0.0.0.0/0"]
      target_tags   = ["ssh"]
      allow = [{
        protocol = "tcp"
        ports    = ["22"]
      }]
    }
  }
  
  create_nat = true
  nat_region = "asia-southeast2"
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project_id | GCP project ID | string | required |
| network_name | VPC network name | string | required |
| subnets | Subnet configurations | map | {} |
| firewall_rules | Firewall rule configurations | map | {} |
| create_nat | Create Cloud NAT | bool | false |

## Outputs

| Name | Description |
|------|-------------|
| network_id | VPC network ID |
| subnets | Map of subnet details |
| router_name | Cloud Router name |