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

module "compute" {
  source = "../../modules/compute"

  project_id = var.project_id
  network    = module.networking.network_self_link

  # Add compute instances as needed
  instances = {
    web-01 = {
      name                = "${var.environment}-web-01"
      machine_type        = "e2-micro"
      zone                = "${var.region}-a"
      subnetwork          = module.networking.subnets["subnet-01"].self_link
      tags                = ["ssh", "http-server"]
      enable_external_ip  = true
      labels             = {
        environment = var.environment
        role        = "web-server"
      }
      
    }
    # Example for another instance:
    # app-01 = {
    #   name                = "${var.environment}-app-01"
    #   machine_type        = "e2-small"
    #   zone                = "${var.region}-b"
    #   subnetwork          = module.networking.subnets["subnet-01"].self_link
    #   tags                = ["ssh"]
    #   enable_external_ip  = false
    # }
  }
}