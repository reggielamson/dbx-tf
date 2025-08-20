variable "github_configuration" {
  description = "GitHub integration configuration"
  type = object({
    personal_access_token = string
    git_username         = optional(string)
    git_provider         = optional(string, "gitHub")
  })
  default = null
}

variable "workspace_configuration" {
  description = "General workspace configuration settings"
  type        = map(string)
  default     = {}
}

variable "workspace_entitlements" {
  description = "Workspace-level entitlements for specific principals"
  type = map(object({
    principal_type = string  # user, group, or service_principal
    principal_id   = string  # ID of the principal

    allow_cluster_create        = optional(bool)
    allow_instance_pool_create  = optional(bool)
    databricks_sql_access       = optional(bool)
    workspace_access            = optional(bool)
  }))
  default = {}

  validation {
    condition = alltrue([
      for key, config in var.workspace_entitlements :
      contains(["user", "group", "service_principal"], config.principal_type)
    ])
    error_message = "Principal type must be 'user', 'group', or 'service_principal'."
  }
}

variable "group_roles" {
  description = "Group role assignments for IAM and instance profiles"
  type = map(object({
    group_id = string  # ID of the group (not name)
    role     = string  # iam or instance-profile

    # For IAM roles
    iam_role_arn = optional(string)

    # For instance profiles
    instance_profile_arn = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for key, config in var.group_roles :
      contains(["iam", "instance-profile"], config.role)
    ])
    error_message = "Role must be either 'iam' or 'instance-profile'."
  }

  validation {
    condition = alltrue([
      for key, config in var.group_roles :
      (config.role == "iam" && config.iam_role_arn != null) ||
      (config.role == "instance-profile" && config.instance_profile_arn != null)
    ])
    error_message = "When role is 'iam', iam_role_arn must be provided. When role is 'instance-profile', instance_profile_arn must be provided."
  }
}

variable "service_tokens" {
  description = "Service tokens to create"
  type = map(object({
    comment          = string
    lifetime_seconds = optional(number, 7776000)  # 90 days default

    # Token permissions
    permissions = optional(object({
      access_control_list = optional(list(object({
        user_name              = optional(string)
        group_name             = optional(string)
        service_principal_name = optional(string)
        permission_level       = string  # CAN_USE, CAN_MANAGE
      })), [])
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for key, token in var.service_tokens :
      token.lifetime_seconds >= 3600 && token.lifetime_seconds <= 31536000  # 1 hour to 1 year
    ])
    error_message = "Token lifetime must be between 3600 seconds (1 hour) and 31536000 seconds (1 year)."
  }
}

variable "existing_groups" {
  description = "Map of existing group names to their IDs (for group roles and permissions)"
  type        = map(string)
  default     = {}
}

variable "existing_users" {
  description = "Map of existing user names to their IDs (for token permissions)"
  type        = map(string)
  default     = {}
}

variable "existing_service_principals" {
  description = "Map of existing service principal names to their IDs (for token permissions)"
  type        = map(string)
  default     = {}
}

# modules/databricks-workspace-config/locals.tf

locals {
  # Separate IAM roles from instance profiles
  iam_roles = {
    for key, config in var.group_roles : key => config
    if config.role == "iam"
  }

  instance_profiles = {
    for key, config in var.group_roles : key => config
    if config.role == "instance-profile"
  }

  # Prepare GitHub configuration for workspace_conf
  github_config = var.github_configuration != null ? {
    "gitUsername" = var.github_configuration.git_username
    "gitProvider" = var.github_configuration.git_provider
    "personalAccessToken" = var.github_configuration.personal_access_token
  } : {}

  # Filter out null values from workspace entitlements for each principal
  filtered_entitlements = {
    for key, config in var.workspace_entitlements : key => {
      principal_type = config.principal_type
      principal_id   = config.principal_id
      entitlements = {
        for ent_key, ent_value in {
          allow_cluster_create       = config.allow_cluster_create
          allow_instance_pool_create = config.allow_instance_pool_create
          databricks_sql_access      = config.databricks_sql_access
          workspace_access           = config.workspace_access
        } : ent_key => ent_value
        if ent_value != null
      }
    }
  }

  # Flatten token permissions for easier iteration
  token_permissions = flatten([
    for token_key, token in var.service_tokens : [
      for acl in coalesce(token.permissions.access_control_list, []) : {
        token_key                  = token_key
        user_name                 = acl.user_name
        group_name                = acl.group_name
        service_principal_name    = acl.service_principal_name
        permission_level          = acl.permission_level
      }
    ] if token.permissions != null
  ])
}