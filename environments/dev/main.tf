module "networking" {
  source = "../../modules/networking"

  project_id   = var.project_id
  network_name = "${var.environment}-vpc"

  subnets = {
    subnet-01 = {
      subnet_name          = "${var.environment}-subnet-01"
      subnet_ip            = "10.0.1.0/24"
      subnet_region        = var.region
      subnet_private_access = true
    }
  }

  firewall_rules = {
    allow-ssh = {
      name          = "${var.environment}-allow-ssh"
      source_ranges = ["0.0.0.0/0"]
      target_tags   = ["ssh"]
      allow = [{
        protocol = "tcp"
        ports    = ["22"]
      }]
    }
    allow-http = {
      name          = "${var.environment}-allow-http"
      source_ranges = ["0.0.0.0/0"]
      target_tags   = ["http-server"]
      allow = [{
        protocol = "tcp"
        ports    = ["80"]
      }]
    }
    allow-internal = {
      name          = "${var.environment}-allow-internal"
      source_ranges = ["10.0.0.0/8"]
      allow = [{
        protocol = "tcp"
        ports    = ["0-65535"]
      }]
    }
    allow-icmp = {
      name          = "${var.environment}-allow-icmp"
      source_ranges = ["10.0.0.0/8"]
      allow = [{
        protocol = "icmp"
      }]
    }
  }

  create_nat = true
  nat_region = var.region
}