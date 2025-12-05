# Dev Environment

Development environment with networking, compute, storage, IAM, and optional GKE cluster.

## What's Running

**Enabled:**
- VPC with subnets (including GKE subnet with secondary ranges)
- Cloud NAT and firewall rules
- Sample compute instance
- Storage bucket
- IAM service accounts and Workload Identity setup

**Disabled (uncomment in main.tf):**
- GKE private cluster
- GKE public cluster (testing only)

## Quick Start

```bash
# Setup
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project_id

# Deploy
terraform init
terraform plan
terraform apply
```

## Enable GKE

1. Enable API: `gcloud services enable container.googleapis.com`
2. Uncomment `gke_private` module in main.tf
3. Update `master_authorized_networks` with your IP
4. Run `terraform apply`

## Connect to GKE

```bash
gcloud container clusters get-credentials dev-private-cluster \
  --region asia-southeast2 \
  --project YOUR_PROJECT_ID
```

## Workload Identity Setup

The IAM bindings are already created. Just need to set up the K8s side:

```bash
kubectl create serviceaccount app-backend-ksa -n default
kubectl annotate serviceaccount app-backend-ksa \
  iam.gke.io/gcp-service-account=dev-app-backend@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

Then use it in your pods:
```yaml
spec:
  serviceAccountName: app-backend-ksa
```

## Service Accounts

- `dev-gke-nodes` - Node pools (logging, monitoring)
- `dev-app-backend` - App workloads (storage viewer)

## Costs

Without GKE: ~$50/month (NAT + compute instance)
With GKE: ~$100/month (add node pool costs)

## Common Issues

**Can't connect to cluster?**
Add your IP to master_authorized_networks in main.tf

**Pods can't access GCP services?**
Check Workload Identity annotation on the K8s service account

## Files

- `main.tf` - All module configs
- `variables.tf` - Input variables
- `outputs.tf` - Outputs
- `terraform.tfvars` - Your values (gitignored)

## Related Docs

- [GKE Private Module](../../modules/gke-private/README.md)
- [IAM Module](../../modules/iam/README.md)
- [GKE Architecture Guide](../../docs/GKE_ARCHITECTURE.md)