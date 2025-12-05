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
    
    # GKE subnet with secondary ranges for pods and services
    gke-subnet = {
      subnet_name           = "${var.environment}-gke-subnet"
      subnet_ip             = "10.0.10.0/24"
      subnet_region         = var.region
      subnet_private_access = true
      
      secondary_ranges = [
        {
          range_name    = "pods"
          ip_cidr_range = "10.1.0.0/16"
        },
        {
          range_name    = "services"
          ip_cidr_range = "10.2.0.0/20"
        }
      ]
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

    # Testing import instance
    # dev-testing = {
    #   name               = "${var.environment}-testing"
    #   machine_type       = "e2-small"
    #   zone               = "${var.region}-a"
    #   subnetwork         = module.networking.subnets["subnet-01"].self_link
    #   tags               = ["ssh", "http-server"]
    #   enable_external_ip = true
    #   labels = {
    #     environment = var.environment
    #     role        = "web-server"
    #   }
    # }
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

# IAM setup for GKE
module "iam" {
  source = "../../modules/iam"

  project_id = var.project_id

  service_accounts = {
    gke-nodes = {
      account_id   = "${var.environment}-gke-nodes"
      display_name = "GKE Nodes Service Account"
      description  = "Service account for GKE node pools"
    }
    app-backend = {
      account_id   = "${var.environment}-app-backend"
      display_name = "Application Backend Service Account"
      description  = "Service account for backend application workloads"
    }
  }

  # Give GKE nodes logging and monitoring permissions
  project_iam_bindings = {
    gke-logging = {
      role   = "roles/logging.logWriter"
      member = "serviceAccount:${var.environment}-gke-nodes@${var.project_id}.iam.gserviceaccount.com"
    }
    gke-monitoring = {
      role   = "roles/monitoring.metricWriter"
      member = "serviceAccount:${var.environment}-gke-nodes@${var.project_id}.iam.gserviceaccount.com"
    }
    gke-metric-viewer = {
      role   = "roles/monitoring.viewer"
      member = "serviceAccount:${var.environment}-gke-nodes@${var.project_id}.iam.gserviceaccount.com"
    }
    # Let app backend read from storage
    app-storage-viewer = {
      role   = "roles/storage.objectViewer"
      member = "serviceAccount:${var.environment}-app-backend@${var.project_id}.iam.gserviceaccount.com"
    }
  }

  # Workload Identity binding - connects K8s SA to Google SA
  workload_identity_bindings = {
    app-backend = {
      service_account_id = "projects/${var.project_id}/serviceAccounts/${var.environment}-app-backend@${var.project_id}.iam.gserviceaccount.com"
      namespace          = "default"
      ksa_name           = "app-backend-ksa"
    }
  }
}

# GKE Private Cluster - uncomment to deploy
# module "gke_private" {
#   source = "../../modules/gke-private"
#
#   project_id   = var.project_id
#   cluster_name = "${var.environment}-private-cluster"
#   location     = var.region
#
#   network    = module.networking.network_self_link
#   subnetwork = module.networking.subnets["gke-subnet"].self_link
#
#   pods_secondary_range_name     = "pods"
#   services_secondary_range_name = "services"
#
#   master_ipv4_cidr_block       = "172.16.0.0/28"
#   enable_private_endpoint      = false
#   master_global_access_enabled = true
#
#   # Update with your IP for kubectl access
#   master_authorized_networks = [
#     {
#       cidr_block   = "10.0.0.0/8"
#       display_name = "Internal VPC"
#     }
#     # {
#     #   cidr_block   = "YOUR_IP/32"
#     #   display_name = "My IP"
#     # }
#   ]
#
#   kubernetes_version = "1.28"
#   release_channel    = "REGULAR"
#
#   enable_shielded_nodes       = true
#   enable_binary_authorization = false
#   network_policy              = true
#
#   node_pools = {
#     general = {
#       name               = "general-pool"
#       machine_type       = "e2-standard-2"
#       initial_node_count = 1
#       disk_size_gb       = 50
#       service_account    = module.iam.service_account_emails["gke-nodes"]
#
#       autoscaling = {
#         min_node_count = 1
#         max_node_count = 3
#       }
#
#       auto_repair  = true
#       auto_upgrade = true
#
#       labels = {
#         environment   = var.environment
#         workload_type = "general"
#       }
#     }
#   }
#
#   maintenance_window = {
#     start_time = "03:00"
#   }
#
#   labels = {
#     environment = var.environment
#     managed_by  = "terraform"
#   }
# }