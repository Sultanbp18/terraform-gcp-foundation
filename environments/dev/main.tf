# Setup VPC networking
module "networking" {
  source = "../../modules/networking"

  project_id   = var.project_id
  network_name = "${var.environment}-vpc"

  subnets = {
    subnet-01 = {
      subnet_name           = "${var.environment}-subnet-01"
      subnet_ip             = "10.0.1.0/24"
      subnet_region         = var.region
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

# Setup compute instances
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
      service_account = {
        email = null
        scopes = [null]
      }
      enable_external_ip  = true
      labels             = {
        environment = var.environment
        role        = "web-server"
      }

    }
    dev-testing = {
      name               = "${var.environment}-testing"
      machine_type       = "e2-small"
      zone               = "${var.region}-a"
      subnetwork         = module.networking.subnets["subnet-01"].self_link
      tags               = ["ssh", "http-server"]
      enable_external_ip = true
      labels = {
        environment = var.environment
        role        = "web-server"
      }
      service_account = {
        email = "84443983999-compute@developer.gserviceaccount.com"
        scopes = [
          "https://www.googleapis.com/auth/devstorage.read_only",
          "https://www.googleapis.com/auth/logging.write",
          "https://www.googleapis.com/auth/monitoring.write",
          "https://www.googleapis.com/auth/service.management.readonly",
          "https://www.googleapis.com/auth/servicecontrol",
          "https://www.googleapis.com/auth/trace.append",
        ]
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

# Setup Cloud Storage buckets
module "storage" {
  source = "../../modules/storage"

  project_id = var.project_id
  labels     = { environment = var.environment }

  # Add storage buckets as needed
  buckets = {
    app-data = {
      name               = "${var.project_id}-${var.environment}-data" # Unique bucket name
      location           = var.region
      storage_class      = "STANDARD"
      versioning_enabled = true # Enable versioning for important data
      force_destroy      = true # Set false in production
      labels = {
        environment = var.environment
        purpose     = "app-data"
      }
    }
    # Example for another bucket:
    # logs = {
    #   name               = "${var.project_id}-${var.environment}-logs"
    #   location           = var.region
    #   storage_class      = "STANDARD"
    #   versioning_enabled = false
    #   force_destroy      = true
    # }
  }
}