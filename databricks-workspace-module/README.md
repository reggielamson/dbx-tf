# Databricks Workspace Module

This Terraform module creates and manages a complete Databricks workspace with all supporting infrastructure including credentials, storage, networking, encryption, Unity Catalog, and workspace configuration. It's designed to be error-free and follows all lessons learned from previous modules.

## Features

- **Complete Workspace Setup**: Creates all required and optional workspace components
- **Flexible Configuration**: Support for both new workspace creation and existing workspace management
- **Network Integration**: Optional VPC networking configuration
- **Security**: Customer managed key encryption support
- **Unity Catalog**: Metastore assignment for data governance
- **Access Control**: IP access list management
- **Workspace Settings**: Custom workspace configuration
- **Error Prevention**: Comprehensive validation and dependency management

## Architecture Components

1. **MWS Credentials**: AWS IAM role for Databricks to access your AWS account
2. **Storage Configuration**: S3 bucket configuration for workspace storage
3. **Network Configuration**: (Optional) VPC, subnets, and security groups
4. **Customer Managed Keys**: (Optional) KMS encryption for data at rest
5. **Workspace**: The actual Databricks workspace
6. **Metastore Assignment**: (Optional) Unity Catalog metastore for data governance
7. **IP Access Lists**: Network access control
8. **Workspace Configuration**: Custom workspace settings

## Usage Examples

### Basic Workspace (Minimum Configuration)

```hcl
module "databricks_workspace" {
  source = "../databricks-workspace-module"

  workspace = {
    workspace_name  = "my-databricks-workspace"
    deployment_name = "my-deployment"
    aws_region     = "us-west-2"
    account_id     = "123456789012"
    pricing_tier   = "PREMIUM"
    
    custom_tags = {
      Environment = "production"
      Team        = "data-engineering"
      Project     = "analytics-platform"
    }
  }

  credentials = {
    credentials_name = "databricks-cross-account-role"
    role_arn        = "arn:aws:iam::123456789012:role/databricks-cross-account-role"
  }

  storage_configuration = {
    storage_configuration_name = "databricks-root-storage"
    bucket_name               = "my-databricks-workspace-bucket"
  }
}
```

### Full Configuration with All Features

```hcl
module "databricks_workspace" {
  source = "../databricks-workspace-module"

  workspace = {
    workspace_name  = "enterprise-databricks-workspace"
    deployment_name = "enterprise-deployment"
    aws_region     = "us-east-1"
    account_id     = "123456789012"
    pricing_tier   = "ENTERPRISE"
    
    custom_tags = {
      Environment = "production"
      Team        = "data-platform"
      CostCenter  = "engineering"
      Owner       = "data-team@company.com"
    }
  }

  credentials = {
    credentials_name = "databricks-enterprise-role"
    role_arn        = "arn:aws:iam::123456789012:role/databricks-enterprise-role"
  }

  storage_configuration = {
    storage_configuration_name = "enterprise-workspace-storage"
    bucket_name               = "enterprise-databricks-workspace-bucket"
  }

  # VPC configuration for network isolation
  network_configuration = {
    network_name       = "databricks-enterprise-network"
    vpc_id            = "vpc-12345678"
    subnet_ids        = ["subnet-12345678", "subnet-87654321"]
    security_group_ids = ["sg-12345678"]
  }

  # Customer managed encryption
  customer_managed_key = {
    key_alias  = "databricks-workspace-key"
    key_arn    = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    key_region = "us-east-1"
    use_cases  = ["MANAGED_SERVICES", "STORAGE"]
  }

  # Unity Catalog integration
  metastore_assignment = {
    metastore_id         = "metastore-12345678-1234-1234-1234-123456789012"
    default_catalog_name = "main"
  }

  # IP access control
  ip_access_lists = {
    "corporate-network" = {
      label        = "Corporate Network Access"
      list_type    = "ALLOW"
      ip_addresses = ["10.0.0.0/8", "192.168.1.0/24"]
      enabled      = true
    }
    
    "blocked-regions" = {
      label        = "Blocked Geographic Regions"
      list_type    = "BLOCK"
      ip_addresses = ["203.0.113.0/24"]
      enabled      = true
    }
  }

  # Workspace configuration
  workspace_configuration = {
    "enableIpAccessLists"                    = "true"
    "enableTokensConfig"                     = "true"
    "maxTokenLifetimeDays"                   = "90"
    "enableDeprecatedClusterNamedInitScripts" = "false"
    "enableDeprecatedGlobalInitScripts"      = "false"
    "enableWebTerminal"                      = "true"
    "enableResultsDownloading"               = "true"
  }
}
```

### Managing Existing Workspace

```hcl
module "existing_databricks_workspace" {
  source = "../databricks-workspace-module"

  # Don't create workspace, manage existing one
  enable_workspace_creation = false
  existing_workspace_id    = "1234567890123456"

  workspace = {
    workspace_name = "existing-workspace"  # Used for reference only
    aws_region    = "us-west-2"
    account_id    = "123456789012"
  }

  # Still need credentials and storage for reference
  credentials = {
    credentials_name = "existing-credentials"
    role_arn        = "arn:aws:iam::123456789012:role/existing-role"
  }

  storage_configuration = {
    storage_configuration_name = "existing-storage"
    bucket_name               = "existing-bucket"
  }

  # Configure IP access lists for existing workspace
  ip_access_lists = {
    "new-office-network" = {
      label        = "New Office Network"
      list_type    = "ALLOW"
      ip_addresses = ["172.16.0.0/16"]
      enabled      = true
    }
  }

  # Update workspace settings
  workspace_configuration = {
    "maxTokenLifetimeDays" = "30"
    "enableIpAccessLists"  = "true"
  }
}
```

### Multi-Environment Setup

```hcl
# Development Workspace
module "dev_workspace" {
  source = "../databricks-workspace-module"

  workspace = {
    workspace_name  = "dev-analytics-workspace"
    deployment_name = "dev-analytics"
    aws_region     = "us-west-2"
    account_id     = var.account_id
    pricing_tier   = "STANDARD"
    
    custom_tags = {
      Environment = "development"
      Team        = "data-engineering"
    }
  }

  credentials = {
    credentials_name = "databricks-dev-role"
    role_arn        = var.dev_role_arn
  }

  storage_configuration = {
    storage_configuration_name = "dev-workspace-storage"
    bucket_name               = "dev-databricks-workspace-${random_string.suffix.result}"
  }

  workspace_configuration = {
    "enableIpAccessLists" = "false"  # More permissive for dev
    "maxTokenLifetimeDays" = "30"
  }
}

# Production Workspace  
module "prod_workspace" {
  source = "../databricks-workspace-module"

  workspace = {
    workspace_name  = "prod-analytics-workspace"
    deployment_name = "prod-analytics"
    aws_region     = "us-west-2"
    account_id     = var.account_id
    pricing_tier   = "ENTERPRISE"
    
    custom_tags = {
      Environment = "production"
      Team        = "data-engineering"
      Compliance  = "required"
    }
  }

  credentials = {
    credentials_name = "databricks-prod-role"
    role_arn        = var.prod_role_arn
  }

  storage_configuration = {
    storage_configuration_name = "prod-workspace-storage"
    bucket_name               = "prod-databricks-workspace-${random_string.suffix.result}"
  }

  # Production security features
  network_configuration = {
    network_name       = "prod-databricks-network"
    vpc_id            = var.prod_vpc_id
    subnet_ids        = var.prod_subnet_ids
    security_group_ids = var.prod_security_group_ids
  }

  customer_managed_key = {
    key_alias  = "databricks-prod-key"
    key_arn    = var.prod_kms_key_arn
    key_region = "us-west-2"
    use_cases  = ["MANAGED_SERVICES", "STORAGE"]
  }

  metastore_assignment = {
    metastore_id         = var.unity_catalog_metastore_id
    default_catalog_name = "production"
  }

  ip_access_lists = {
    "corporate-vpn" = {
      label        = "Corporate VPN"
      list_type    = "ALLOW"
      ip_addresses = var.corporate_ip_ranges
      enabled      = true
    }
  }

  workspace_configuration = {
    "enableIpAccessLists"     = "true"
    "enableTokensConfig"      = "true"
    "maxTokenLifetimeDays"    = "90"
    "enableWebTerminal"       = "false"  # Stricter security
    "enableResultsDownloading" = "false"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| workspace | Workspace configuration | `object` | - | yes |
| credentials | AWS credentials configuration | `object` | - | yes |
| storage_configuration | Storage configuration | `object` | - | yes |
| network_configuration | Network configuration | `object` | `null` | no |
| customer_managed_key | Customer managed key configuration | `object` | `null` | no |
| metastore_assignment | Unity Catalog metastore assignment | `object` | `null` | no |
| ip_access_lists | IP access lists configuration | `map(object)` | `{}` | no |
| workspace_configuration | Workspace configuration settings | `map(string)` | `{}` | no |
| enable_workspace_creation | Whether to create workspace | `bool` | `true` | no |
| existing_workspace_id | Existing workspace ID | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| workspace | Created workspace details |
| workspace_id | Workspace ID |
| workspace_url | Workspace URL |
| credentials | Created credentials configuration |
| storage_configuration | Created storage configuration |
| network_configuration | Created network configuration |
| customer_managed_key | Created CMK configuration |
| metastore_assignment | Metastore assignment details |
| ip_access_lists | Created IP access lists |
| workspace_configuration | Applied workspace configuration |

## Design Principles

This module follows these principles to prevent errors:

1. **Clear Dependencies**: Explicit dependency management between resources
2. **Conditional Creation**: Proper handling of optional components
3. **Type Consistency**: All conditionals return consistent types
4. **Comprehensive Validation**: Input validation prevents configuration errors
5. **Flexible Architecture**: Support for both new and existing workspaces
6. **Security First**: Built-in security best practices
7. **Error Prevention**: Lessons learned from previous modules applied

## Prerequisites

Before using this module, ensure you have:

1. **AWS IAM Role**: Cross-account role for Databricks
2. **S3 Bucket**: For workspace root storage
3. **VPC Setup**: (Optional) VPC, subnets, security groups for network isolation
4. **KMS Key**: (Optional) Customer managed key for encryption
5. **Unity Catalog**: (Optional) Metastore for data governance
6. **Databricks Account**: Account-level access for workspace creation

## Security Considerations

- **Network Isolation**: Use VPC configuration for production workspaces
- **Encryption**: Enable customer managed keys for sensitive data
- **Access Control**: Configure IP access lists appropriately
- **Token Management**: Set reasonable token lifetime limits
- **Monitoring**: Enable audit logs and monitoring
- **Least Privilege**: Follow principle of least privilege for IAM roles

This module provides a complete, production-ready solution for Databricks workspace management with comprehensive security and governance features.