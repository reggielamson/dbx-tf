# Databricks Workspace Configuration Module

This Terraform module manages workspace-level configurations for Databricks including GitHub integration, workspace settings, entitlements, group roles, service tokens, and permissions. It's designed to be error-free and follows all lessons learned from previous modules.

## Features

- **GitHub Integration**: Configure Git credentials and provider settings
- **Workspace Settings**: General workspace configuration parameters
- **Entitlements**: Workspace-level permission settings
- **Group Roles**: IAM role and instance profile assignments to groups
- **Service Tokens**: Create and manage service tokens with permissions
- **Access Control**: Token permission management
- **Error Prevention**: Comprehensive validation and safe resource handling

## Usage Examples

### Basic Workspace Configuration

```hcl
module "databricks_workspace_config" {
  source = "../databricks-workspace-configuration-module"

  # General workspace settings
  workspace_configuration = {
    "enableIpAccessLists"     = "true"
    "enableTokensConfig"      = "true"
    "maxTokenLifetimeDays"    = "90"
    "enableWebTerminal"       = "true"
    "enableResultsDownloading" = "false"
  }

  # Workspace entitlements for specific principals
  workspace_entitlements = {
    "data-engineers-group" = {
      principal_type              = "group"
      principal_id               = "group-id-1234"
      allow_cluster_create       = true
      allow_instance_pool_create = true
      databricks_sql_access      = true
      workspace_access           = true
    }
  }
}
```

### GitHub Integration Setup

```hcl
module "databricks_workspace_config" {
  source = "../databricks-workspace-configuration-module"

  # GitHub integration
  github_configuration = {
    personal_access_token = var.github_pat
    git_username         = "databricks-service"
    git_provider         = "gitHub"
  }

  workspace_configuration = {
    "enableGitVersioning" = "true"
    "gitIntegrationEnabled" = "true"
  }
}
```

### Comprehensive Configuration with Group Roles and Tokens

```hcl
module "databricks_workspace_config" {
  source = "../databricks-workspace-configuration-module"

  # GitHub integration
  github_configuration = {
    personal_access_token = var.github_personal_access_token
    git_username         = "company-databricks"
    git_provider         = "gitHub"
  }

  # Workspace settings
  workspace_configuration = {
    "enableIpAccessLists"                    = "true"
    "enableTokensConfig"                     = "true"
    "maxTokenLifetimeDays"                   = "30"
    "enableDeprecatedClusterNamedInitScripts" = "false"
    "enableDeprecatedGlobalInitScripts"      = "false"
    "enableWebTerminal"                      = "false"
    "enableResultsDownloading"               = "false"
    "enableGitVersioning"                    = "true"
    "enforceUserIsolation"                   = "true"
  }

  # Workspace entitlements for specific principals
  workspace_entitlements = {
    "data-engineers-group" = {
      principal_type              = "group"
      principal_id               = "group-id-1234"
      allow_cluster_create       = true
      allow_instance_pool_create = false
      databricks_sql_access      = true
      workspace_access           = true
    }
    
    "admin-user" = {
      principal_type              = "user"
      principal_id               = "user-id-5678"
      allow_cluster_create       = true
      allow_instance_pool_create = true
      databricks_sql_access      = true
      workspace_access           = true
    }
  }

  # Group role assignments
  group_roles = {
    "data-engineers-iam" = {
      group_id     = "group-id-1234"  # Use group ID, not name
      role         = "iam"
      iam_role_arn = "arn:aws:iam::123456789012:role/databricks-data-engineer-role"
    }
    
    "ml-team-instance-profile" = {
      group_id             = "group-id-5678"  # Use group ID, not name
      role                = "instance-profile"
      instance_profile_arn = "arn:aws:iam::123456789012:instance-profile/databricks-ml-instance-profile"
    }
    
    "analytics-team-iam" = {
      group_id     = "group-id-9012"  # Use group ID, not name
      role         = "iam"
      iam_role_arn = "arn:aws:iam::123456789012:role/databricks-analytics-role"
    }
  }

  # Service tokens with permissions
  service_tokens = {
    "ci-cd-token" = {
      comment          = "CI/CD Pipeline Token"
      lifetime_seconds = 2592000  # 30 days
      
      permissions = {
        access_control_list = [
          {
            group_name       = "devops-team"
            permission_level = "CAN_USE"
          },
          {
            service_principal_name = "ci-cd-service-principal"
            permission_level       = "CAN_USE"
          }
        ]
      }
    }
    
    "monitoring-token" = {
      comment          = "Monitoring and Alerting Token"
      lifetime_seconds = 7776000  # 90 days
      
      permissions = {
        access_control_list = [
          {
            group_name       = "sre-team"
            permission_level = "CAN_MANAGE"
          },
          {
            user_name        = "monitoring-admin"
            permission_level = "CAN_USE"
          }
        ]
      }
    }
    
    "data-pipeline-token" = {
      comment          = "Data Pipeline Automation Token"
      lifetime_seconds = 15552000  # 180 days
      
      permissions = {
        access_control_list = [
          {
            group_name       = "data-engineers"
            permission_level = "CAN_USE"
          }
        ]
      }
    }
  }

  # Reference existing entities
  existing_groups = {
    "data-engineers" = "group-id-1234"
    "ml-engineers"   = "group-id-5678"
    "analytics-team" = "group-id-9012"
    "devops-team"    = "group-id-3456"
    "sre-team"       = "group-id-7890"
  }

  existing_users = {
    "monitoring-admin" = "user-id-1111"
  }

  existing_service_principals = {
    "ci-cd-service-principal" = "sp-id-2222"
  }
}
```

### Environment-Specific Configuration

```hcl
# Development Environment
module "dev_workspace_config" {
  source = "../databricks-workspace-configuration-module"

  workspace_configuration = {
    "enableIpAccessLists"       = "false"  # More permissive for dev
    "maxTokenLifetimeDays"      = "7"      # Shorter token life
    "enableWebTerminal"         = "true"   # Allow web terminal
    "enableResultsDownloading"  = "true"   # Allow downloads
    "enforceUserIsolation"      = "false"  # Less strict
  }

  workspace_entitlements = {
    allow_cluster_create       = true
    allow_instance_pool_create = true
    databricks_sql_access      = true
  }

  service_tokens = {
    "dev-testing-token" = {
      comment          = "Development Testing Token"
      lifetime_seconds = 604800  # 7 days
    }
  }
}

# Production Environment
module "prod_workspace_config" {
  source = "../databricks-workspace-configuration-module"

  github_configuration = {
    personal_access_token = var.prod_github_pat
    git_username         = "prod-databricks"
    git_provider         = "gitHub"
  }

  workspace_configuration = {
    "enableIpAccessLists"                    = "true"
    "enableTokensConfig"                     = "true"
    "maxTokenLifetimeDays"                   = "30"
    "enableDeprecatedClusterNamedInitScripts" = "false"
    "enableDeprecatedGlobalInitScripts"      = "false"
    "enableWebTerminal"                      = "false"  # Disable for security
    "enableResultsDownloading"               = "false"  # Disable for security
    "enforceUserIsolation"                   = "true"   # Strict isolation
    "enableAuditLogs"                        = "true"
  }

  workspace_entitlements = {
    allow_cluster_create       = false  # Controlled cluster creation
    allow_instance_pool_create = false
    databricks_sql_access      = true
    workspace_access           = true
  }

  group_roles = {
    "prod-data-engineers" = {
      group_name   = "prod-data-engineers"
      role         = "iam"
      iam_role_arn = var.prod_data_engineer_role_arn
    }
  }

  service_tokens = {
    "prod-automation-token" = {
      comment          = "Production Automation Token"
      lifetime_seconds = 7776000  # 90 days
      
      permissions = {
        access_control_list = [
          {
            group_name       = "prod-automation-group"
            permission_level = "CAN_USE"
          }
        ]
      }
    }
  }
}
```

### Integration with User Management Module

```hcl
# First create users and groups
module "databricks_users_groups" {
  source = "./modules/databricks-user-group-management"
  
  users = {
    "data_engineer_1" = {
      user_name = "engineer1@company.com"
      groups    = ["data-engineers"]
    }
  }
  
  groups = {
    "data-engineers" = {
      display_name              = "Data Engineers"
      allow_cluster_create      = true
      allow_instance_pool_create = true
    }
  }
}

# Then configure workspace with references to created groups
module "workspace_config" {
  source = "../databricks-workspace-configuration-module"
  
  workspace_configuration = {
    "enableTokensConfig" = "true"
    "maxTokenLifetimeDays" = "60"
  }
  
  group_roles = {
    "data-engineers-role" = {
      group_name   = "data-engineers"
      role         = "iam"
      iam_role_arn = var.data_engineer_role_arn
    }
  }
  
  service_tokens = {
    "team-token" = {
      comment = "Data Engineering Team Token"
      lifetime_seconds = 5184000  # 60 days
      
      permissions = {
        access_control_list = [
          {
            group_name       = "data-engineers"
            permission_level = "CAN_USE"
          }
        ]
      }
    }
  }
  
  # Reference the created groups
  existing_groups = module.databricks_users_groups.groups
  
  depends_on = [module.databricks_users_groups]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| github_configuration | GitHub integration configuration | `object` | `null` | no |
| workspace_configuration | General workspace configuration settings | `map(string)` | `{}` | no |
| workspace_entitlements | Workspace-level entitlements | `object` | `{}` | no |
| group_roles | Group role assignments for IAM and instance profiles | `map(object)` | `{}` | no |
| service_tokens | Service tokens to create | `map(object)` | `{}` | no |
| existing_groups | Map of existing group names to their IDs | `map(string)` | `{}` | no |
| existing_users | Map of existing user names to their IDs | `map(string)` | `{}` | no |
| existing_service_principals | Map of existing service principal names to their IDs | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| github_configuration | Applied GitHub configuration (sensitive) |
| workspace_configuration | Applied workspace configuration |
| workspace_entitlements | Applied workspace entitlements |
| group_roles | Created group role assignments |
| service_tokens | Created service tokens (sensitive) |
| token_values | Service token values (highly sensitive) |
| token_permissions | Applied token permissions |

## Common Workspace Configuration Options

### Security Settings
```hcl
workspace_configuration = {
  "enableIpAccessLists"     = "true"
  "enableTokensConfig"      = "true"
  "maxTokenLifetimeDays"    = "30"
  "enforceUserIsolation"    = "true"
  "enableWebTerminal"       = "false"
  "enableResultsDownloading" = "false"
}
```

### Git Integration Settings
```hcl
workspace_configuration = {
  "enableGitVersioning"     = "true"
  "gitIntegrationEnabled"   = "true"
  "defaultGitBranch"        = "main"
}
```

### Cluster and Job Settings
```hcl
workspace_configuration = {
  "enableDeprecatedClusterNamedInitScripts" = "false"
  "enableDeprecatedGlobalInitScripts"       = "false"
  "enableAutomaticClusterUpdate"            = "true"
}
```

## Design Principles

This module follows these principles to prevent errors:

1. **Plan-time Determinism**: All count/for_each decisions use input variables
2. **Clear Separation**: Different configuration types are handled separately
3. **Comprehensive Validation**: Input validation prevents configuration errors
4. **Safe Defaults**: Reasonable defaults for optional parameters
5. **Sensitive Data Handling**: Proper marking of sensitive outputs
6. **Type Consistency**: All conditionals return consistent types
7. **Error Prevention**: Lessons learned from all previous modules applied

## Security Considerations

- **Token Management**: Set appropriate lifetime limits for service tokens
- **Permission Principles**: Follow least privilege for token permissions
- **GitHub Integration**: Secure PAT storage and rotation
- **Workspace Settings**: Enable security features for production
- **Role Assignments**: Careful IAM role and instance profile assignments
- **Audit Logging**: Enable audit features for compliance

This module provides comprehensive workspace configuration management while maintaining reliability and security best practices.