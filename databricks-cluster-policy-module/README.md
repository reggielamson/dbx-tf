# Databricks Cluster Policy Module

This Terraform module creates and manages Databricks cluster policies with predefined templates and custom configurations. It provides flexible policy creation for different use cases like cost control, security, data engineering, and ML workloads.

## Features

- **Predefined Policy Types**: Ready-to-use templates for common scenarios
- **Custom Policy Support**: Full flexibility with custom JSON policy definitions
- **Permission Management**: Set access controls on policies
- **Tag Enforcement**: Require specific tags on clusters
- **Resource Restrictions**: Control instance types, sizes, and runtime versions
- **Security Controls**: Enforce encryption, disable SSH, etc.
- **Cost Management**: Auto-termination and resource limits

## Policy Types

### 1. Cost Control (`cost_control`)
- Enforces auto-termination limits
- Requires cost-center tags
- Controls resource usage

### 2. Security (`security`)
- Enables local disk encryption
- Disables SSH public keys
- Disables elastic disk for compliance

### 3. Data Engineering (`data_engineering`)
- Optimized for ETL workloads
- Reasonable auto-termination windows
- Autoscaling configurations

### 4. ML Workload (`ml_workload`)
- Optimized instance types for ML
- Enables elastic disk
- Memory-optimized configurations

### 5. Custom (`custom`)
- Full control over policy definition
- Use JSON policy definition or variables

## Usage Examples

### Basic Cost Control Policy
```hcl
module "cluster_policies" {
  source = "../databricks-cluster-policy-module"
  
  policies = {
    "cost-control-policy" = {
      name                     = "Cost Control Policy"
      description              = "Enforces cost controls and tagging"
      policy_type              = "cost_control"
      auto_termination_minutes = 60
      max_workers             = 10
      required_tags = {
        "cost-center" = "data-team"
        "environment" = "production"
      }
    }
  }
}
```

### Security Policy with Permissions
```hcl
module "cluster_policies" {
  source = "../databricks-cluster-policy-module"
  
  policies = {
    "security-policy" = {
      name        = "High Security Policy"
      description = "Enforces security best practices"
      policy_type = "security"
      
      allowed_instance_types = ["m5.large", "m5.xlarge"]
      enable_ssh_public_keys = false
      
      permissions = {
        access_control_list = [
          {
            group_name       = "security-admins"
            permission_level = "CAN_USE"
          },
          {
            group_name       = "data-engineers"
            permission_level = "CAN_USE"
          }
        ]
      }
    }
  }
}
```

### Data Engineering Policy
```hcl
module "cluster_policies" {
  source = "../databricks-cluster-policy-module"
  
  policies = {
    "data-eng-policy" = {
      name        = "Data Engineering Policy"
      policy_type = "data_engineering"
      
      min_workers              = 2
      max_workers              = 20
      enable_autoscaling       = true
      auto_termination_minutes = 180
      
      allowed_runtime_versions = ["11.3.x-scala2.12", "12.2.x-scala2.12"]
      enable_elastic_disk     = true
    }
  }
}
```

### Custom Policy with Full Control
```hcl
module "cluster_policies" {
  source = "../databricks-cluster-policy-module"
  
  policies = {
    "custom-policy" = {
      name        = "Custom Advanced Policy"
      policy_type = "custom"
      
      policy_definition = {
        "spark_version" = {
          "type"   = "fixed"
          "value"  = "11.3.x-scala2.12"
          "hidden" = true
        }
        "node_type_id" = {
          "type"   = "allowlist"
          "values" = ["i3.xlarge", "i3.2xlarge"]
        }
        "autotermination_minutes" = {
          "type"         = "range"
          "minValue"     = 30
          "maxValue"     = 240
          "defaultValue" = 120
        }
        "custom_tags.team" = {
          "type"  = "fixed"
          "value" = "data-platform"
        }
      }
    }
  }
}
```

### Multiple Policies with Common Settings
```hcl
module "cluster_policies" {
  source = "../databricks-cluster-policy-module"
  
  common_settings = {
    default_auto_termination_minutes = 90
    organization_required_tags = {
      "managed-by" = "terraform"
      "owner"      = "data-team"
    }
  }
  
  policies = {
    "dev-policy" = {
      name                     = "Development Policy"
      policy_type              = "cost_control"
      auto_termination_minutes = 30
      max_workers             = 5
    }
    
    "prod-policy" = {
      name                = "Production Policy"
      policy_type         = "security"
      max_workers         = 50
      force_auto_termination = false
      
      permissions = {
        access_control_list = [
          {
            group_name       = "production-users"
            permission_level = "CAN_USE"
          }
        ]
      }
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| policies | Map of cluster policies to create | `map(object)` | `{}` | no |
| default_tags | Default tags to apply to all policies | `map(string)` | `{}` | no |
| common_settings | Common settings for all policies | `object` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_policies | Created cluster policies with their IDs and details |
| policy_ids | Map of policy names to their IDs |
| policy_definitions | The processed policy definitions |

## Policy Variable Options

Each policy in the `policies` map supports:

- `name`: Policy display name (required)
- `description`: Policy description
- `policy_type`: Template type (custom, cost_control, security, data_engineering, ml_workload)
- `policy_definition`: Custom JSON policy (for custom type)
- `auto_termination_minutes`: Maximum auto-termination time
- `force_auto_termination`: Force fixed auto-termination
- `allowed_instance_types` / `denied_instance_types`: Control node types
- `allowed_driver_instance_types` / `denied_driver_instance_types`: Control driver types
- `min_workers` / `max_workers`: Control cluster size
- `enable_autoscaling`: Enable/disable autoscaling
- `allowed_runtime_versions` / `denied_runtime_versions`: Control Spark versions
- `allow_spot_instances`: Allow spot instances
- `spot_bid_max_percent`: Maximum spot bid percentage
- `enable_local_disk_encryption`: Force disk encryption
- `enable_ssh_public_keys`: Allow/deny SSH keys
- `enable_elastic_disk`: Control elastic disk
- `required_tags`: Tags that must be set on clusters
- `permissions`: Access control settings

This module provides both simplicity for common use cases and flexibility for advanced scenarios.