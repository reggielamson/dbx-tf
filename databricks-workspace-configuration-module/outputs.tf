output "github_configuration" {
  description = "Applied GitHub configuration"
  value = var.github_configuration != null ? {
    applied = true
    git_provider = var.github_configuration.git_provider
    git_username = var.github_configuration.git_username
  } : null
  sensitive = true  # Contains token info
}

output "workspace_configuration" {
  description = "Applied workspace configuration"
  value = length(var.workspace_configuration) > 0 ? {
    custom_config = length(databricks_workspace_conf.workspace_config) > 0 ? databricks_workspace_conf.workspace_config[0].custom_config : var.workspace_configuration
  } : null
}

output "workspace_entitlements" {
  description = "Applied workspace entitlements"
  value = {
    for k, v in databricks_entitlements.workspace_entitlements : k => {
      principal_type = local.filtered_entitlements[k].principal_type
      principal_id   = local.filtered_entitlements[k].principal_id
      entitlements   = local.filtered_entitlements[k].entitlements
    }
  }
}

output "group_roles" {
  description = "Created group role assignments"
  value = {
    iam_roles = {
      for k, v in databricks_group_role.iam_roles : k => {
        id       = v.id
        group_id = v.group_id
        role     = v.role
      }
    }
    instance_profiles = {
      for k, v in databricks_group_role.instance_profiles : k => {
        id       = v.id
        group_id = v.group_id
        role     = v.role
      }
    }
  }
}

output "service_tokens" {
  description = "Created service tokens (values are sensitive)"
  value = {
    for k, v in databricks_token.service_tokens : k => {
      id               = v.id
      comment          = v.comment
      lifetime_seconds = v.lifetime_seconds
      creation_time    = v.creation_time
      expiry_time      = v.expiry_time
    }
  }
  sensitive = true
}

output "token_values" {
  description = "Service token values (highly sensitive)"
  value = {
    for k, v in databricks_token.service_tokens : k => v.token_value
  }
  sensitive = true
}

output "token_permissions" {
  description = "Applied token permissions"
  value = length(var.service_tokens) > 0 ? {
    authorization = length(databricks_permissions.token_permissions) > 0 ? databricks_permissions.token_permissions[0].authorization : null
    object_type   = length(databricks_permissions.token_permissions) > 0 ? databricks_permissions.token_permissions[0].object_type : null
  } : null
}