variable "groups" {
  description = "Map of groups to create with their properties and workspace assignments"
  type = map(object({
    display_name                   = string
    external_id                   = optional(string)
    allow_cluster_create          = optional(bool, false)
    allow_instance_pool_create    = optional(bool, false)
    databricks_sql_access         = optional(bool, false)
    workspace_access              = optional(bool, true)

    # Workspace assignments
    workspace_assignments = optional(list(object({
      workspace_id = string
      permissions  = optional(list(string), ["USER"])
    })), [])

    # Members to add to the group
    user_members = optional(list(string), [])
    service_principal_members = optional(list(string), [])
    group_members = optional(list(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for group_key, group in var.groups : alltrue([
        for assignment in group.workspace_assignments :
        alltrue([for perm in assignment.permissions : contains(["USER", "ADMIN"], perm)])
      ])
    ])
    error_message = "Workspace assignment permissions must be 'USER' or 'ADMIN'."
  }
}

variable "existing_users" {
  description = "Map of existing user names to their IDs (for adding to groups)"
  type        = map(string)
  default     = {}
}

variable "existing_service_principals" {
  description = "Map of existing service principal names to their IDs (for adding to groups)"
  type        = map(string)
  default     = {}
}

variable "existing_groups" {
  description = "Map of existing group names to their IDs (for nested group membership)"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# modules/databricks-groups-workspace/locals.tf

locals {
  # Flatten workspace assignments for easier iteration
  workspace_assignments = flatten([
    for group_key, group in var.groups : [
      for assignment in group.workspace_assignments : {
        group_key    = group_key
        group_name   = group.display_name
        workspace_id = assignment.workspace_id
        permissions  = assignment.permissions
      }
    ]
  ])

  # Flatten user memberships
  user_memberships = flatten([
    for group_key, group in var.groups : [
      for user_name in group.user_members : {
        group_key  = group_key
        user_name  = user_name
        user_id    = lookup(var.existing_users, user_name, null)
      } if lookup(var.existing_users, user_name, null) != null
    ]
  ])

  # Flatten service principal memberships
  sp_memberships = flatten([
    for group_key, group in var.groups : [
      for sp_name in group.service_principal_members : {
        group_key = group_key
        sp_name   = sp_name
        sp_id     = lookup(var.existing_service_principals, sp_name, null)
      } if lookup(var.existing_service_principals, sp_name, null) != null
    ]
  ])

  # Flatten group memberships (nested groups)
  group_memberships = flatten([
    for group_key, group in var.groups : [
      for nested_group_name in group.group_members : {
        parent_group_key = group_key
        nested_group_name = nested_group_name
        nested_group_id  = lookup(var.existing_groups, nested_group_name, null)
      } if lookup(var.existing_groups, nested_group_name, null) != null
    ]
  ])
}