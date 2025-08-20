# Databricks Groups with Workspace Assignments Module

This Terraform module creates and manages Databricks groups with workspace assignments and membership management. It's designed to be simple, reliable, and avoid the type consistency issues common in complex Terraform configurations.

## Features

- Create Databricks groups with configurable permissions
- Assign groups to multiple workspaces with different permission levels
- Manage group memberships (users, service principals, nested groups)
- Support for existing users/service principals/groups via ID mappings
- Comprehensive validation and error handling
- Clean separation of concerns

## Usage

### Basic Group Creation with Workspace Assignment

```hcl
module "databricks_groups" {
  source = "../databricks-groups-module"

  groups = {
    "data-engineers" = {
      display_name              = "Data Engineers"
      allow_cluster_create      = true
      allow_instance_pool_create = true
      databricks_sql_access     = true
      
      workspace_assignments = [
        {
          workspace_id = "123456789"
          permissions  = ["USER"]
        },
        {
          workspace_id = "987654321"
          permissions  = ["ADMIN"]
        }
      ]
      
      user_members = ["john.doe", "jane.smith"]
      service_principal_members = ["etl-service"]
    }
    
    "data-analysts" = {
      display_name          = "Data Analysts"
      databricks_sql_access = true
      
      workspace_assignments = [
        {
          workspace_id = "123456789"
          permissions  = ["USER"]
        }
      ]
      
      user_members = ["alice.wilson", "bob.johnson"]
    }
  }

  # Map existing users to their IDs
  existing_users = {
    "john.doe"     = "user-id-1234"
    "jane.smith"   = "user-id-5678"
    "alice.wilson" = "user-id-9012"
    "bob.johnson"  = "user-id-3456"
  }

  # Map existing service principals to their IDs
  existing_service_principals = {
    "etl-service" = "sp-id-7890"
  }
}
```

### Integration with User Management Module

```hcl
# Create users first
module "databricks_users" {
  source = "./modules/databricks-user-group-management"
  
  users = {
    "john_doe" = {
      user_name    = "john.doe@company.com"
      display_name = "John Doe"
    }
    "jane_smith" = {
      user_name    = "jane.smith@company.com"
      display_name = "Jane Smith"
    }
  }
}

# Create groups and assign users
module "databricks_groups" {
  source = "../databricks-groups-module"
  
  groups = {
    "engineering-team" = {
      display_name              = "Engineering Team"
      allow_cluster_create      = true
      databricks_sql_access     = true
      
      workspace_assignments = [
        {
          workspace_id = var.prod_workspace_id
          permissions  = ["USER"]
        },
        {
          workspace_id = var.dev_workspace_id
          permissions  = ["ADMIN"]
        }
      ]
      
      user_members = ["john_doe", "jane_smith"]
    }
  }
  
  # Pass user IDs from the user module
  existing_users = module.databricks_users.users
  
  depends_on = [module.databricks_users]
}
```

### Nested Group Hierarchies

```hcl
module "databricks_groups" {
  source = "../databricks-groups-module"

  groups = {
    # Parent groups
    "all-data-team" = {
      display_name = "All Data Team"
      databricks_sql_access = true
      
      workspace_assignments = [
        {
          workspace_id = "123456789"
          permissions  = ["USER"]
        }
      ]
      
      # Include other groups as members
      group_members = ["data-engineers", "data-analysts"]
    }
    
    # Child groups
    "data-engineers" = {
      display_name              = "Data Engineers"
      allow_cluster_create      = true
      allow_instance_pool_create = true
      
      user_members = ["engineer1", "engineer2"]
    }
    
    "data-analysts" = {
      display_name = "Data Analysts"
      
      user_members = ["analyst1", "analyst2"]
    }
  }
  
  existing_users = var.user_id_map
  
  # Map for nested group membership
  existing_groups = {
    "data-engineers" = databricks_group.groups["data-engineers"].id
    "data-analysts"  = databricks_group.groups["data-analysts"].id
  }
}
```

### Multiple Workspace Management

```hcl
module "databricks_groups" {
  source = "../databricks-groups-module"

  groups = {
    "platform-admins" = {
      display_name              = "Platform Administrators"
      allow_cluster_create      = true
      allow_instance_pool_create = true
      databricks_sql_access     = true
      
      # Assign to multiple workspaces with different permissions
      workspace_assignments = [
        {
          workspace_id = var.prod_workspace_id
          permissions  = ["ADMIN"]
        },
        {
          workspace_id = var.staging_workspace_id
          permissions  = ["ADMIN"]
        },
        {
          workspace_id = var.dev_workspace_id
          permissions  = ["ADMIN"]
        }
      ]
    }
    
    "developers" = {
      display_name = "Developers"
      databricks_sql_access = true
      
      workspace_assignments = [
        {
          workspace_id = var.dev_workspace_id
          permissions  = ["USER"]
        },
        {
          workspace_id = var.staging_workspace_id
          permissions  = ["USER"]
        }
      ]
    }
  }
  
  existing_users = var.all_users
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| groups | Map of groups to create with properties and assignments | `map(object)` | `{}` | no |
| existing_users | Map of existing user names to their IDs | `map(string)` | `{}` | no |
| existing_service_principals | Map of existing service principal names to their IDs | `map(string)` | `{}` | no |
| existing_groups | Map of existing group names to their IDs | `map(string)` | `{}` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Group Object Structure

Each group in the `groups` map supports:

- `display_name` (required): Group display name
- `external_id` (optional): External ID for group
- `allow_cluster_create` (optional, default: false): Allow cluster creation
- `allow_instance_pool_create` (optional, default: false): Allow instance pool creation
- `databricks_sql_access` (optional, default: false): Enable SQL access
- `workspace_access` (optional, default: true): Enable workspace access
- `workspace_assignments` (optional): List of workspace assignments
- `user_members` (optional): List of user names to add as members
- `service_principal_members` (optional): List of service principal names to add
- `group_members` (optional): List of group names for nested membership

## Workspace Assignment Structure

Each workspace assignment supports:
- `workspace_id` (required): Target workspace ID
- `permissions` (optional, default: ["USER"]): List of permissions (USER, ADMIN)

## Outputs

| Name | Description |
|------|-------------|
| groups | Created groups with their IDs and details |
| group_ids | Map of group keys to their IDs |
| workspace_assignments | Summary of workspace assignments |
| group_memberships | Summary of all group memberships |

## Design Principles

This module follows these principles learned from previous iterations:

1. **Type Consistency**: All conditionals return consistent types
2. **Simple Logic**: Avoids complex nested conditionals and functions
3. **Clear Separation**: Separates concerns into distinct resources
4. **Flexible Integration**: Works with existing resources via ID mappings
5. **Comprehensive Validation**: Validates inputs to prevent runtime errors
6. **Predictable Outputs**: Provides structured outputs for integration

## Error Prevention

- Uses `lookup()` with null checks to handle missing references gracefully
- Validates permission values to prevent invalid assignments
- Separates flattening logic into locals for clarity
- Avoids complex merge operations that cause type issues