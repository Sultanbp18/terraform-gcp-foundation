# IAM Module

Manages Google Cloud IAM resources including service accounts, IAM bindings, custom roles, and Workload Identity bindings for GKE.

## Features

- **Service Accounts**: Create and manage GCP service accounts
- **IAM Bindings**: Manage project-level and service account IAM permissions
- **Custom Roles**: Define custom IAM roles with specific permissions
- **Workload Identity**: Configure Workload Identity bindings for GKE pods
- **Service Account Keys**: Generate service account keys (use sparingly)

## Usage

### Basic Service Account Creation

```hcl
module "iam" {
  source = "../../modules/iam"

  project_id = "my-project-id"

  service_accounts = {
    gke-app = {
      account_id   = "gke-app-sa"
      display_name = "GKE Application Service Account"
      description  = "Service account for GKE application workloads"
    }
  }
}
```

### Service Account with Project IAM Binding

```hcl
module "iam" {
  source = "../../modules/iam"

  project_id = "my-project-id"

  service_accounts = {
    storage-admin = {
      account_id   = "storage-admin-sa"
      display_name = "Storage Admin Service Account"
    }
  }

  project_iam_bindings = {
    storage-admin = {
      role   = "roles/storage.admin"
      member = "serviceAccount:storage-admin-sa@my-project-id.iam.gserviceaccount.com"
    }
  }
}
```

### Workload Identity for GKE

```hcl
module "iam" {
  source = "../../modules/iam"

  project_id = "my-project-id"

  service_accounts = {
    app-backend = {
      account_id   = "app-backend-sa"
      display_name = "App Backend Service Account"
    }
  }

  workload_identity_bindings = {
    app-backend = {
      service_account_id = "projects/my-project-id/serviceAccounts/app-backend-sa@my-project-id.iam.gserviceaccount.com"
      namespace          = "default"
      ksa_name           = "app-backend-ksa"
    }
  }

  project_iam_bindings = {
    app-backend-storage = {
      role   = "roles/storage.objectViewer"
      member = "serviceAccount:app-backend-sa@my-project-id.iam.gserviceaccount.com"
    }
  }
}
```

### Custom IAM Role

```hcl
module "iam" {
  source = "../../modules/iam"

  project_id = "my-project-id"

  custom_roles = {
    limited-compute = {
      role_id     = "limitedComputeRole"
      title       = "Limited Compute Role"
      description = "Custom role with limited compute permissions"
      permissions = [
        "compute.instances.get",
        "compute.instances.list",
        "compute.zones.list"
      ]
      stage = "GA"
    }
  }
}
```

### Complete Example with Multiple Features

```hcl
module "iam" {
  source = "../../modules/iam"

  project_id = "my-project-id"

  # Create service accounts
  service_accounts = {
    gke-app = {
      account_id   = "gke-app-sa"
      display_name = "GKE Application Service Account"
      description  = "Service account for GKE workloads"
    }
    ci-cd = {
      account_id   = "ci-cd-sa"
      display_name = "CI/CD Pipeline Service Account"
      description  = "Service account for CI/CD operations"
    }
  }

  # Project-level IAM bindings
  project_iam_bindings = {
    gke-storage = {
      role   = "roles/storage.objectViewer"
      member = "serviceAccount:gke-app-sa@my-project-id.iam.gserviceaccount.com"
    }
    ci-cd-permissions = {
      role   = "roles/container.developer"
      member = "serviceAccount:ci-cd-sa@my-project-id.iam.gserviceaccount.com"
    }
  }

  # Workload Identity bindings
  workload_identity_bindings = {
    gke-app = {
      service_account_id = "projects/my-project-id/serviceAccounts/gke-app-sa@my-project-id.iam.gserviceaccount.com"
      namespace          = "production"
      ksa_name           = "app-ksa"
    }
  }

  # Custom roles
  custom_roles = {
    app-viewer = {
      role_id     = "appViewer"
      title       = "Application Viewer"
      description = "Read-only access to application resources"
      permissions = [
        "storage.objects.get",
        "storage.objects.list",
        "logging.logEntries.list"
      ]
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_id | The GCP project ID | `string` | n/a | yes |
| service_accounts | Map of service accounts to create | `map(object)` | `{}` | no |
| project_iam_bindings | Map of project-level IAM bindings | `map(object)` | `{}` | no |
| service_account_iam_bindings | Map of service account IAM bindings | `map(object)` | `{}` | no |
| custom_roles | Map of custom IAM roles to create | `map(object)` | `{}` | no |
| workload_identity_bindings | Map of Workload Identity bindings for GKE | `map(object)` | `{}` | no |
| service_account_keys | Map of service account keys to create | `map(object)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| service_accounts | Map of created service accounts with details |
| service_account_emails | Map of service account emails |
| service_account_keys | Map of created service account keys (sensitive) |
| custom_roles | Map of created custom roles |
| project_iam_bindings | Map of project IAM bindings |

## Best Practices

1. **Prefer Workload Identity over Service Account Keys**
   - Use Workload Identity for GKE workloads
   - Avoid creating service account keys when possible
   - Keys should be short-lived and rotated regularly

2. **Principle of Least Privilege**
   - Grant only necessary permissions
   - Use predefined roles when available
   - Create custom roles for specific use cases

3. **Service Account Naming**
   - Use descriptive names (e.g., `gke-app-sa`, `ci-cd-sa`)
   - Include environment prefix for clarity
   - Follow organizational naming conventions

4. **IAM Binding Organization**
   - Group related bindings logically
   - Document why specific permissions are needed
   - Regular audit of IAM permissions

5. **Conditional IAM Policies**
   - Use conditions for temporary access
   - Implement time-based restrictions
   - Add resource-based conditions when needed

## Security Considerations

- **Service Account Keys**: Treat as sensitive credentials, rotate regularly
- **Workload Identity**: Preferred method for GKE authentication
- **Audit Logging**: Enable Cloud Audit Logs for IAM changes
- **Regular Reviews**: Periodically review and remove unused service accounts
- **Separation of Duties**: Use different service accounts for different workloads

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| google | >= 5.0.0 |

## Resources Created

- `google_service_account` - Service accounts
- `google_project_iam_member` - Project-level IAM bindings
- `google_service_account_iam_member` - Service account IAM bindings
- `google_project_iam_custom_role` - Custom IAM roles
- `google_service_account_key` - Service account keys (optional)

## Related Modules

- [GKE Private](../gke-private/README.md) - Private GKE clusters with Workload Identity
- [GKE Public](../gke-public/README.md) - Public GKE clusters
- [Networking](../networking/README.md) - VPC and network resources

## Support

For issues or questions, please refer to the main project documentation.