# Azure DevOps Repository Sync Module

This Terraform module synchronizes an Azure DevOps repository with a public GitHub repository. It monitors both repositories for changes and automatically updates the Azure DevOps repository when the GitHub repository is updated.

## Features

- **Automatic Sync**: Monitors GitHub repository for changes and syncs to Azure DevOps
- **Configurable Branch/Tag**: Sync from any GitHub branch or tag
- **Change Detection**: Only syncs when actual changes are detected
- **Force Sync**: Option to force synchronization regardless of changes
- **Authentication**: Uses existing Azure CLI authentication or environment variables
- **Cleanup**: Automatic cleanup of temporary files

## Usage

```hcl
module "repo_sync" {
  source = "./modules-tf/github-ado-repo-sync"
  
  ecp_azure_devops_organization_name = "my-org"
  ecp_azure_devops_project_name      = "my-project"
  ecp_azure_devops_repository_name   = "my-ado-repo"
  
  # Local submodule configuration
  local_submodule_path = "../../lib/ecp-automation"  # Path to local submodule
  
  ecp_azure_devops_target_branch = "main"
  sync_enabled                   = true
  force_sync                     = false
}
```

## Requirements

- Terraform >= 1.0
- Azure CLI installed and authenticated
- Git installed
- PowerShell Core (pwsh)
- Access to both GitHub repository (read) and Azure DevOps repository (read/write)

## Provider Configuration

### GitHub Provider Setup

For **public repositories**, no authentication is required:

```hcl
provider "github" {
  # No token required for public repositories
}
```

For **private repositories** or to avoid rate limiting, configure a Personal Access Token:

```hcl
provider "github" {
  token = var.github_token
}
```

#### Creating a GitHub Personal Access Token (PAT)

1. Go to GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. Click **"Generate new token (classic)"**
3. Configure the token:
   - **Note**: `terraform-ado-sync`
   - **Expiration**: Choose appropriate duration (90 days recommended)
   - **Scopes**: Select `public_repo` (for public repos) or `repo` (for private repos)
4. Click **"Generate token"**
5. Copy the token immediately (you won't see it again)

#### Secure Token Storage

**Option 1: Environment Variable (Recommended)**
```bash
export TF_VAR_github_token="ghp_your_token_here"
```

**Option 2: Terraform Variables File**
```hcl
# terraform.tfvars (add to .gitignore)
github_token = "ghp_your_token_here"
```

**Option 3: Azure Key Vault (Enterprise)**
```hcl
data "azurerm_key_vault_secret" "github_token" {
  name         = "github-pat"
  key_vault_id = var.key_vault_id
}

provider "github" {
  token = data.azurerm_key_vault_secret.github_token.value
}
```

### Enterprise Authentication with Entra ID

For organizations using **Entra ID (Azure AD)**, there are several service principal and managed identity approaches:

#### **Option 1: GitHub App with Entra ID Integration (Recommended)**

1. **Create GitHub App**:
   - Go to GitHub Organization → **Settings** → **Developer settings** → **GitHub Apps**
   - Click **"New GitHub App"**
   - Configure:
     - **Name**: `Azure-DevOps-Sync-App`
     - **Homepage URL**: Your organization URL
     - **Webhook URL**: Leave blank for now
   - **Permissions**:
     - Repository permissions: `Contents: Read`, `Metadata: Read`
     - Organization permissions: `Members: Read` (if needed)
   - Generate and download **private key**

2. **Store Private Key in Key Vault**:
   ```bash
   az keyvault secret set --vault-name "your-keyvault" --name "github-app-private-key" --file "your-app.private-key.pem"
   ```

3. **Configure Terraform**:
   ```hcl
   data "azurerm_key_vault_secret" "github_app_key" {
     name         = "github-app-private-key"
     key_vault_id = var.key_vault_id
   }
   
   provider "github" {
     app_auth {
       id              = var.github_app_id      # App ID from GitHub
       installation_id = var.github_install_id # Installation ID
       pem_file        = data.azurerm_key_vault_secret.github_app_key.value
     }
   }
   ```

#### **Option 2: Azure DevOps Service Connection with GitHub**

1. **Create Service Connection**:
   - Azure DevOps → **Project Settings** → **Service connections**
   - **New service connection** → **GitHub**
   - Choose **OAuth** or **Personal Access Token**
   - For OAuth: Uses Azure AD identity federation

2. **Use in Terraform**:
   ```hcl
   data "azuredevops_serviceendpoint_github" "github_connection" {
     project_id            = var.project_id
     service_endpoint_name = "GitHub-Enterprise-Connection"
   }
   
   # Access token through service connection
   locals {
     github_token = data.azuredevops_serviceendpoint_github.github_connection.authorization.scheme == "Token" ? 
       data.azuredevops_serviceendpoint_github.github_connection.authorization.parameters.accessToken : null
   }
   ```

#### **Option 3: Workload Identity Federation (Azure → GitHub)**

1. **Configure in GitHub** (Organization level):
   - **Settings** → **Security** → **Secrets and variables** → **Actions**
   - Add **AZURE_CLIENT_ID**, **AZURE_TENANT_ID**, **AZURE_SUBSCRIPTION_ID**

2. **Azure Managed Identity**:
   ```hcl
   resource "azurerm_user_assigned_identity" "github_sync" {
     name                = "github-sync-identity"
     resource_group_name = var.resource_group_name
     location           = var.location
   }
   
   resource "azurerm_federated_identity_credential" "github" {
     name                = "github-actions"
     resource_group_name = var.resource_group_name
     audience            = ["api://AzureADTokenExchange"]
     issuer             = "https://token.actions.githubusercontent.com"
     parent_id          = azurerm_user_assigned_identity.github_sync.id
     subject            = "repo:your-org/your-repo:ref:refs/heads/main"
   }
   ```

3. **GitHub Actions Workflow** (for token generation):
   ```yaml
   # .github/workflows/generate-token.yml
   name: Generate Azure Token for Terraform
   on: workflow_dispatch
   
   permissions:
     id-token: write
     contents: read
   
   jobs:
     generate-token:
       runs-on: ubuntu-latest
       steps:
         - uses: azure/login@v1
           with:
             client-id: ${{ secrets.AZURE_CLIENT_ID }}
             tenant-id: ${{ secrets.AZURE_TENANT_ID }}
             subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
         
         - name: Get GitHub Token from Key Vault
           run: |
             TOKEN=$(az keyvault secret show --vault-name "your-kv" --name "github-pat" --query "value" -o tsv)
             echo "::add-mask::$TOKEN"
             echo "GITHUB_TOKEN=$TOKEN" >> $GITHUB_ENV
   ```

#### **Option 4: Azure AD Application Registration**

1. **Register Application**:
   ```bash
   az ad app create --display-name "GitHub-Terraform-Sync" --sign-in-audience "AzureADMyOrg"
   ```

2. **Create Service Principal**:
   ```bash
   az ad sp create --id <app-id>
   ```

3. **Configure Certificate Authentication**:
   ```bash
   # Generate certificate
   openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
   
   # Upload to Azure AD
   az ad app credential reset --id <app-id> --cert @cert.pem
   
   # Store in Key Vault
   az keyvault certificate import --vault-name "your-kv" --name "github-sync-cert" --file cert.pem
   ```

4. **Use in Terraform**:
   ```hcl
   data "azurerm_key_vault_certificate" "github_cert" {
     name         = "github-sync-cert"
     key_vault_id = var.key_vault_id
   }
   
   # Use certificate for Azure authentication, then retrieve GitHub token
   provider "azurerm" {
     features {}
     client_id                   = var.azure_client_id
     client_certificate_path     = data.azurerm_key_vault_certificate.github_cert.certificate_data_base64
     tenant_id                   = var.azure_tenant_id
     subscription_id             = var.azure_subscription_id
   }
   ```

#### **Recommendation for Enterprise**

For **production environments**, use **Option 1 (GitHub App)** combined with **Azure Key Vault**:

- ✅ **No user dependency**: App belongs to organization
- ✅ **Fine-grained permissions**: Scoped to specific repositories
- ✅ **Audit trail**: All API calls logged to organization
- ✅ **Token rotation**: Automatic token generation
- ✅ **Entra ID integration**: Certificates stored in Key Vault
- ✅ **Compliance**: Meets enterprise security requirements

## Authentication

The module uses Azure CLI authentication for Azure DevOps access. Ensure you're logged in:

```bash
az login
az devops configure --defaults organization=https://dev.azure.com/YOUR_ORG
```

Alternatively, set the `AZURE_DEVOPS_EXT_PAT` environment variable with a Personal Access Token.

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ecp_azure_devops_organization_name | Azure DevOps organization name | `string` | n/a | yes |
| ecp_azure_devops_project_name | Azure DevOps project name | `string` | n/a | yes |
| ecp_azure_devops_repository_name | Azure DevOps repository name | `string` | n/a | yes |
| github_repository_owner | GitHub repository owner/organization | `string` | n/a | yes |
| github_repository_name | GitHub repository name | `string` | n/a | yes |
| github_branch_or_tag | GitHub branch or tag to sync from | `string` | `"main"` | no |
| ecp_azure_devops_target_branch | Target branch in Azure DevOps | `string` | `"main"` | no |
| sync_enabled | Enable or disable synchronization | `bool` | `true` | no |
| force_sync | Force sync even if no changes detected | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| azure_devops_repository_id | Azure DevOps repository ID |
| azure_devops_repository_url | Azure DevOps repository clone URL |
| github_repository_url | GitHub repository URL |
| github_default_branch | GitHub repository default branch |
| sync_trigger | Current sync trigger value |
| last_github_commit | Latest commit SHA from GitHub |
| sync_enabled | Whether synchronization is enabled |

## How It Works

1. **Data Sources**: The module uses data sources to check the current commit state of both repositories
2. **Change Detection**: A `terraform_data` resource triggers when commits change in either repository
3. **Synchronization**: A PowerShell script clones both repositories, copies files, and pushes changes
4. **Authentication**: Uses Azure CLI context for Azure DevOps authentication
5. **Cleanup**: Temporary directories are automatically cleaned up

## Improvements and Suggestions

### Current Implementation Benefits:
- ✅ Pure Terraform solution with no external dependencies
- ✅ Automatic change detection
- ✅ Configurable sync targets
- ✅ Proper cleanup and error handling

### Potential Improvements:
1. **Webhook-based Sync**: Instead of polling, implement GitHub webhooks to trigger Azure DevOps pipeline
2. **Incremental Sync**: Use git operations to sync only changed files/commits
3. **Conflict Resolution**: Add logic to handle merge conflicts
4. **Multi-branch Support**: Sync multiple branches simultaneously
5. **Selective Sync**: Option to exclude certain files/directories
6. **Notification**: Add Teams/Slack notifications on sync completion

### Alternative Architecture:
Consider using Azure DevOps service connections with GitHub for native integration:
```hcl
# Alternative: Use native Azure DevOps GitHub integration
resource "azuredevops_serviceendpoint_github" "github" {
  project_id            = data.azuredevops_project.this.id
  service_endpoint_name = "GitHub"
  # Configure GitHub service connection
}
```

## Troubleshooting

- **Authentication Issues**: Ensure Azure CLI is logged in and has access to the Azure DevOps project
- **Git Errors**: Check that git is installed and accessible from PowerShell
- **Permission Errors**: Verify the service account has read access to GitHub and write access to Azure DevOps
- **Network Issues**: Ensure outbound connectivity to both GitHub and Azure DevOps