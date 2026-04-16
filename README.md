# AKS Infrastructure

Production-grade Azure Kubernetes Service (AKS) infrastructure provisioning using Terraform with GitOps integration, multi-tenant support, and comprehensive security features.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
- [Deployment](#deployment)
- [Infrastructure Components](#infrastructure-components)
- [Multi-Tenant Customer Module](#multi-tenant-customer-module)
- [GitOps Integration](#gitops-integration)
- [Security](#security)
- [Monitoring](#monitoring)
- [Backup and Recovery](#backup-and-recovery)
- [Configuration](#configuration)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)

## Overview

This repository manages the complete lifecycle of an Azure Kubernetes Service (AKS) cluster named `orion-staging` with:

- **Infrastructure as Code**: Terraform-based provisioning and management
- **GitOps**: Flux CD integration for continuous deployment
- **Multi-Tenancy**: Reusable customer module for isolated tenant resources
- **Security**: Azure Key Vault, RBAC, and Azure AD integration
- **Monitoring**: Grafana dashboards with Telegram alerting
- **Backup**: CNPG database backup integration with Azure Storage
- **DNS Management**: Cloudflare integration for domain configuration

**Cluster Specifications:**
- **Name**: orion-staging
- **Location**: West US 2
- **Kubernetes Version**: Latest stable with auto-upgrade
- **Node Pools**: 2 system nodes + 2 user nodes (Standard_D2s_v3)
- **CNI**: Cilium with network policies

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          Azure Cloud                            │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              AKS Cluster (orion-staging)                  │  │
│  │                                                           │  │
│  │  ┌──────────────┐  ┌──────────────┐                       │  │
│  │  │ System Pool  │  │  User Pool   │                       │  │
│  │  │ (2 nodes)    │  │  (2 nodes)   │                       │  │
│  │  └──────────────┘  └──────────────┘                       │  │
│  │                                                           │  │
│  │  CNI: Cilium  │  Network Policies: Enabled                │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │             Supporting Infrastructure                     │  │
│  │                                                           │  │
│  │  ┌─────────────┐  ┌────────────┐  ┌──────────────────┐    │  │
│  │  │ Key Vault   │  │  Storage   │  │  Public IP       │    │  │
│  │  │ (Secrets)   │  │  (Backups) │  │  (Traefik)       │    │  │
│  │  └─────────────┘  └────────────┘  └──────────────────┘    │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │     Terraform State Storage (tf_state_store)              │  │
│  │     - Azure Storage Account                               │  │
│  │     - Versioning & Change Feed Enabled                    │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                          │
                          │ GitOps (Flux CD)
                          ▼
          ┌──────────────────────────────┐
          │   GitHub Repository          │
          │   dapacruz/orion-gitops      │
          │   (Cluster Manifests)        │
          └──────────────────────────────┘
                          │
                          │ DNS Management
                          ▼
          ┌──────────────────────────────┐
          │       Cloudflare             │
          │   - Grafana DNS              │
          │   - Customer DNS             │
          └──────────────────────────────┘
```

## Prerequisites

### Required Tools

- [Terraform](https://www.terraform.io/downloads.html) >= 1.14
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/) >= 1.28
- [kubelogin](https://github.com/Azure/kubelogin) for Azure AD authentication
- Bash shell (macOS/Linux or WSL on Windows)

### Azure Requirements

- Azure subscription with Owner or Contributor access
- Azure AD tenant with appropriate permissions
- Service Principal or Managed Identity for Terraform authentication
- Azure AD group for AKS administrators

### External Services

- **Cloudflare Account**: For DNS management
  - Zone configured for your domain
  - API token with DNS edit permissions
- **GitHub Repository**: For GitOps (https://github.com/dapacruz/orion-gitops)
- **Telegram Bot** (optional): For Grafana alerting

## Repository Structure

```
aks-infra/
├── tf_state_store/              # Terraform remote state backend
│   ├── scripts/
│   │   └── update-backend-config.sh   # Backend configuration updater
│   ├── main.tf                  # Provider configuration
│   ├── storage.tf               # Azure Storage for state files
│   ├── variables.tf             # Variable definitions
│   ├── outputs.tf               # Output values
│   ├── condition.tpl            # RBAC condition template
│   └── secrets.auto.tfvars      # Sensitive variables (git-ignored)
│
├── infra/                       # Main AKS infrastructure
│   ├── modules/
│   │   └── customer/            # Multi-tenant customer module
│   │       ├── main.tf          # Customer resources
│   │       ├── variables.tf     # Module inputs
│   │       └── outputs.tf       # Module outputs
│   ├── main.tf                  # Provider & backend configuration
│   ├── aks.tf                   # AKS cluster definition
│   ├── key-vault.tf             # Azure Key Vault
│   ├── backups.tf               # CNPG backup storage
│   ├── flux.tf                  # Flux GitOps configuration
│   ├── cloudflare.tf            # DNS records
│   ├── customers.tf             # Customer instantiation
│   ├── variables.tf             # Variable definitions
│   ├── outputs.tf               # Output values
│   ├── tf-init.sh               # Manual initialization script
│   ├── config.azurerm.tfbackend # Backend config (git-ignored)
│   └── secrets.auto.tfvars      # Sensitive variables (git-ignored)
│
├── tf-deploy.sh                 # Automated deployment script
├── tf-undeploy.sh               # Automated destruction script
├── .gitignore                   # Git exclusions
└── README.md                    # This file
```

## Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd aks-infra
```

### 2. Configure Secrets

Create `secrets.auto.tfvars` files in both directories:

**tf_state_store/secrets.auto.tfvars:**
```hcl
ARM_SUBSCRIPTION_ID = "your-subscription-id"
```

**infra/secrets.auto.tfvars:**
```hcl
ARM_SUBSCRIPTION_ID    = "your-subscription-id"
CLOUDFLARE_API_TOKEN   = "your-cloudflare-api-token"
CLOUDFLARE_ZONE_ID     = "your-cloudflare-zone-id"
GRAFANA_ADMIN_USER     = "admin"
GRAFANA_ADMIN_PASSWORD = "your-secure-password"
GRAFANA_TELEGRAM_TOKEN = "your-telegram-bot-token"
GRAFANA_TELEGRAM_CHATID = "your-telegram-chat-id"
```

### 3. Authenticate with Azure

```bash
az login
az account set --subscription "your-subscription-id"
```

## Deployment

### Automated Deployment

The easiest way to deploy the entire infrastructure:

```bash
./tf-deploy.sh
```

This script will:
1. Initialize and deploy the Terraform state backend
2. Extract storage account credentials
3. Initialize main infrastructure with remote backend
4. Deploy AKS cluster and all resources
5. Configure kubectl with cluster credentials

### Manual Deployment

#### Step 1: Deploy State Backend

```bash
cd tf_state_store
terraform init
terraform plan
terraform apply
```

#### Step 2: Configure Backend for Main Infrastructure

```bash
cd ../infra
./tf-init.sh
```

#### Step 3: Deploy Main Infrastructure

```bash
terraform plan
terraform apply
```

#### Step 4: Configure kubectl

```bash
az aks get-credentials \
  --resource-group aks-infra \
  --name orion-staging \
  --overwrite-existing
```

### Verify Deployment

```bash
# Check cluster access
kubectl get nodes

# Verify Flux installation
kubectl get pods -n flux-system

# Check customer resources
kubectl get namespaces | grep customer
```

## Infrastructure Components

### AKS Cluster (aks.tf:1)

- **Cluster Name**: orion-staging
- **Location**: West US 2
- **Resource Group**: aks-infra
- **Kubernetes Version**: Auto-upgrade enabled (patch + node image)
- **SKU Tier**: Standard

**Node Pools:**
- **System Pool** (agentpool):
  - Size: Standard_D2s_v3
  - Count: 2 nodes
  - Taints: CriticalAddonsOnly=true:NoSchedule
  - OS: Ubuntu Linux
  - Auto-scaling: Disabled

- **User Pool** (userpool):
  - Size: Standard_D2s_v3
  - Count: 2 nodes
  - OS: Ubuntu Linux
  - Auto-scaling: Disabled

**Networking:**
- Network Plugin: Azure CNI
- Network Plugin Mode: Overlay
- Network Policy: Cilium
- Network Data Plane: Cilium
- Service CIDR: 10.0.0.0/16
- DNS Service IP: 10.0.0.10

**Authentication:**
- Azure RBAC: Enabled
- OIDC Issuer: Enabled
- Workload Identity: Enabled
- Admin Group: 70633b4d-738d-4cf5-9298-2308c86be097

**Maintenance:**
- Auto-upgrade Channel: patch
- Node OS Upgrade Channel: NodeImage
- Maintenance Window: Sunday 2:00 AM UTC (weekly)

### Azure Key Vault (key-vault.tf:1)

Stores sensitive credentials and secrets:

- **Secrets Stored**:
  - Grafana admin credentials
  - Grafana Telegram integration
  - Customer database passwords
  - Blob SAS tokens
  - Storage account names

- **Security**:
  - RBAC authorization enabled
  - Soft delete: 7-day retention
  - Purge protection: Enabled
  - Public network access: Enabled

- **Access**:
  - AKS cluster: Key Vault Secrets User role
  - Current user: Key Vault Administrator role

### Storage Account - Backups (backups.tf:1)

Dedicated storage for CNPG database backups:

- **Account Name**: Dynamic (cnpgbackups + random suffix)
- **Replication**: GRS (Geo-Redundant Storage)
- **Access Tier**: Hot
- **TLS Version**: 1.2 minimum
- **Features**:
  - Blob versioning enabled
  - Change feed enabled
  - Container delete retention: 7 days
  - Blob delete retention: 7 days

### Public IP - Traefik Ingress (aks.tf:20)

Static public IP for ingress controller:

- **Name**: traefik-ingress
- **SKU**: Standard
- **Allocation**: Static
- **Usage**: Ingress traffic routing

### Cloudflare DNS (cloudflare.tf:1)

Manages DNS records:

- **Grafana Dashboard**: grafana.orion-staging.dcinfrastructures.io
- **Customer Records**: Configured per customer module

## Multi-Tenant Customer Module

The customer module (infra/modules/customer/:1) provides isolated resources for each tenant.

### Module Features

- Per-customer backup storage
- Isolated database credentials
- Custom DNS records
- SAS token management
- Key Vault integration

### Module Inputs

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `customer_name` | string | Customer identifier | Required |
| `db_user` | string | Database username | "app" |
| `storage_account_id` | string | Shared storage account | Required |
| `key_vault_id` | string | Azure Key Vault ID | Required |
| `cloudflare_zone_id` | string | Cloudflare zone | Required |
| `traefik_ip_address` | string | Ingress IP address | Required |
| `dns_records` | map(object) | DNS records to create | {} |
| `sas_validity_hours` | number | SAS token validity | 17520 (2 years) |


### Module Resources

1. **Storage Container**: Per-customer blob container for backups
2. **Database Secrets**: Auto-generated password stored in Key Vault
3. **SAS Token**: Temporary credentials for blob access
4. **DNS Records**: A records pointing to Traefik ingress

### Adding a New Customer

Edit `infra/customers.tf`:

```hcl
module "customer2" {
  source = "./modules/customer"

  customer_name      = "customer2"
  db_user            = "app"
  storage_account_id = azurerm_storage_account.cnpg_backups.id
  key_vault_id       = azurerm_key_vault.this.id
  cloudflare_zone_id = var.CLOUDFLARE_ZONE_ID
  traefik_ip_address = azurerm_public_ip.traefik_ingress.ip_address

  dns_records = {
    "customer2" = {
      name    = "customer2.orion-staging.dcinfrastructures.io"
      proxied = false
    }
  }
}
```

Then apply:

```bash
cd infra
terraform plan
terraform apply
```

### Accessing Customer Secrets

Secrets are stored in Azure Key Vault with the following naming:

- Database User: `{customer_name}-db-user`
- Database Password: `{customer_name}-db-password`
- SAS Token: `{customer_name}-blob-sas`
- Storage Account: `{customer_name}-storage-account-name`
- Storage Container: `{customer_name}-storage-container-name`

Retrieve via Azure CLI:

```bash
az keyvault secret show \
  --vault-name <vault-name> \
  --name customer1-db-password \
  --query value -o tsv
```

## GitOps Integration

### Flux CD Configuration (flux.tf:1)

- **Repository**: https://github.com/dapacruz/orion-gitops
- **Branch**: main
- **Kustomizations Path**: ./flux-system
- **Sync Interval**: 5 minutes
- **Scope**: Cluster-wide

### Cluster Variables

A ConfigMap is created in the `flux-system` namespace with cluster-specific variables:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-vars
  namespace: flux-system
data:
  AZURE_KEY_VAULT_NAME: <vault-name>
  AZURE_LOCATION: westus2
  CLUSTER_NAME: orion-staging
  CLOUDFLARE_ZONE_ID: <zone-id>
```

## Security

### Authentication & Authorization

- **Azure AD Integration**: Cluster uses Azure AD for RBAC
- **Admin Group**: Specific Azure AD group (ID: 70633b4d-738d-4cf5-9298-2308c86be097)
- **Workload Identity**: OIDC-based authentication for pods
- **Service Account Authentication**: Enabled for legacy workloads

### Network Security

- **Network Policies**: Cilium network policies enabled
- **Network Plugin**: Cilium for advanced networking features
- **Service Mesh Ready**: Cilium provides service mesh capabilities

### Secrets Management

- **Azure Key Vault**: Centralized secrets storage
- **RBAC**: Role-based access control on vault
- **Soft Delete**: 7-day retention for deleted secrets
- **Purge Protection**: Prevents permanent deletion

### Storage Security

- **TLS 1.2**: Minimum TLS version enforced
- **Encryption at Rest**: Azure-managed encryption
- **SAS Tokens**: Time-limited access tokens
- **Versioning**: Blob versioning enabled for audit trail

### Best Practices

1. Rotate SAS tokens regularly (default: 2 years)
2. Use Azure AD Pod Identity or Workload Identity for pod authentication
3. Enable network policies for pod-to-pod communication
4. Regularly update node images (automated via maintenance window)
5. Review Key Vault access logs periodically

## Monitoring

### Grafana Dashboard

- **URL**: https://grafana.orion-staging.dcinfrastructures.io
- **Credentials**: Stored in Azure Key Vault
  - Secret: `grafana-admin-user`
  - Secret: `grafana-admin-password`

### Telegram Alerting

Grafana integrates with Telegram for notifications:

- **Bot Token**: Stored as `grafana-telegram-token`
- **Chat ID**: Stored as `grafana-telegram-chatid`

### Accessing Grafana Credentials

```bash
# Get admin username
az keyvault secret show \
  --vault-name $(terraform output -raw key_vault_name) \
  --name grafana-admin-user \
  --query value -o tsv

# Get admin password
az keyvault secret show \
  --vault-name $(terraform output -raw key_vault_name) \
  --name grafana-admin-password \
  --query value -o tsv
```

## Backup and Recovery

### CNPG Database Backups

- **Storage**: Azure Blob Storage (GRS)
- **Retention**: 7 days (configurable)
- **Access**: Per-customer SAS tokens
- **Features**:
  - Versioning enabled
  - Change feed for audit
  - Container-level isolation per customer

### Backup Configuration

Each customer has:
- Dedicated storage container
- SAS token for backup access
- Credentials stored in Key Vault

### Restore Process

1. Retrieve customer SAS token from Key Vault
2. Access backup container using SAS token
3. Use CNPG recovery procedures to restore from backup

### Terraform State Backups

- **Backend**: Azure Storage
- **Versioning**: Enabled
- **Change Feed**: Enabled for audit trail
- **Access**: RBAC-controlled with conditional access

## Configuration

### Terraform Variables

**State Backend (tf_state_store/variables.tf:1):**
- `ARM_SUBSCRIPTION_ID`: Azure subscription ID

**Main Infrastructure (infra/variables.tf:1):**
- `ARM_SUBSCRIPTION_ID`: Azure subscription ID
- `CLOUDFLARE_API_TOKEN`: Cloudflare API token
- `CLOUDFLARE_ZONE_ID`: Cloudflare zone ID
- `GRAFANA_ADMIN_USER`: Grafana admin username
- `GRAFANA_ADMIN_PASSWORD`: Grafana admin password
- `GRAFANA_TELEGRAM_TOKEN`: Telegram bot token
- `GRAFANA_TELEGRAM_CHATID`: Telegram chat ID

### Backend Configuration

The `config.azurerm.tfbackend` file (git-ignored) should contain:

```hcl
storage_account_name = "tfstate<random>"
container_name       = "tfstate"
key                  = "terraform.tfstate"
tenant_id            = "your-tenant-id"
subscription_id      = "your-subscription-id"
client_id            = "your-client-id"
client_secret        = "your-client-secret"
```

Update using the helper script:

```bash
cd tf_state_store/scripts
./update-backend-config.sh
```

## Maintenance

### Auto-Upgrade Schedule

- **Maintenance Window**: Sunday 2:00 AM UTC (weekly)
- **Kubernetes Patch**: Automatic
- **Node OS**: Automatic

### Manual Upgrades

```bash
# Check available versions
az aks get-upgrades \
  --resource-group aks-infra \
  --name orion-staging

# Upgrade cluster
az aks upgrade \
  --resource-group aks-infra \
  --name orion-staging \
  --kubernetes-version <version>
```

### Infrastructure Updates

```bash
cd infra
terraform plan
terraform apply
```

### Updating Customer Configuration

1. Edit `infra/customers.tf`
2. Plan and apply changes:

```bash
cd infra
terraform plan -target=module.customer1
terraform apply -target=module.customer1
```

### Rotating SAS Tokens

SAS tokens expire after 2 years (default). To rotate:

```bash
# Trigger recreation
terraform taint 'module.customer1.azurerm_storage_container_sas.this'
terraform apply
```

## Troubleshooting

### Common Issues

#### 1. Unable to Authenticate with AKS

```bash
# Re-authenticate with Azure
az login
kubelogin convert-kubeconfig -l azurecli

# Refresh credentials
az aks get-credentials \
  --resource-group aks-infra \
  --name orion-staging \
  --overwrite-existing
```

#### 2. Terraform State Lock

```bash
# List locks
az lock list --resource-group <resource-group>

# Wait for automatic release or manually break (use with caution)
terraform force-unlock <lock-id>
```

#### 3. Flux Not Syncing

```bash
# Check Flux status
kubectl get pods -n flux-system
kubectl logs -n flux-system deployment/source-controller
kubectl logs -n flux-system deployment/kustomize-controller

# Force reconciliation
flux reconcile source git flux-system
flux reconcile kustomization flux-system
```

#### 4. Key Vault Access Denied

```bash
# Verify RBAC assignment
az role assignment list \
  --scope /subscriptions/<subscription-id>/resourceGroups/aks-infra/providers/Microsoft.KeyVault/vaults/<vault-name>

# Re-apply Key Vault configuration
cd infra
terraform apply -target=azurerm_key_vault.this
```

#### 5. DNS Not Resolving

```bash
# Verify Cloudflare records
dig grafana.orion-staging.dcinfrastructures.io

# Check Terraform outputs
terraform output cloudflare_grafana_record

# Re-apply Cloudflare configuration
terraform apply -target=cloudflare_record.grafana
```

### Logs and Diagnostics

```bash
# AKS cluster logs
az aks show \
  --resource-group aks-infra \
  --name orion-staging

# Node logs
kubectl get nodes
kubectl describe node <node-name>

# Pod logs
kubectl logs -n <namespace> <pod-name>

# Terraform debug
export TF_LOG=DEBUG
terraform plan
```

### Cleanup and Undeployment

**Automated cleanup:**

```bash
./tf-undeploy.sh
```

**Manual cleanup:**

```bash
# Destroy main infrastructure
cd infra
terraform destroy

# Destroy state backend (WARNING: deletes all state)
cd ../tf_state_store
terraform destroy
```

## Contributing

When making changes:

1. Create a feature branch
2. Make changes and test locally
3. Run `terraform fmt` to format code
4. Run `terraform validate` to check syntax
5. Submit pull request with description of changes

## Support

For issues or questions:

- Check [Troubleshooting](#troubleshooting) section
- Review Terraform plan output
- Check Azure Portal for resource status
- Review Flux logs for GitOps issues

## References

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Flux CD Documentation](https://fluxcd.io/docs/)
- [Cilium Documentation](https://docs.cilium.io/)
- [Cloudflare API Documentation](https://developers.cloudflare.com/api/)
