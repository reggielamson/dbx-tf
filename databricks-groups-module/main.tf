resource "databricks_group" "groups" {
  for_each = var.groups

  display_name                   = each.value.display_name
  external_id                   = each.value.external_id
  allow_cluster_create          = each.value.allow_cluster_create
  allow_instance_pool_create    = each.value.allow_instance_pool_create
  databricks_sql_access         = each.value.databricks_sql_access
  workspace_access              = each.value.workspace_access
}

# Workspace assignments
resource "databricks_mws_permission_assignment" "group_workspace_assignments" {
  for_each = {
    for assignment in local.workspace_assignments :
    "${assignment.group_key}-${assignment.workspace_id}" => assignment
  }

  workspace_id = each.value.workspace_id
  principal_id = databricks_group.groups[each.value.group_key].id
  permissions  = each.value.permissions

  depends_on = [databricks_group.groups]
}

# Add users to groups
resource "databricks_group_member" "user_members" {
  for_each = {
    for membership in local.user_memberships :
    "${membership.group_key}-${membership.user_name}" => membership
  }

  group_id  = databricks_group.groups[each.value.group_key].id
  member_id = each.value.user_id

  depends_on = [databricks_group.groups]
}

# Add service principals to groups
resource "databricks_group_member" "sp_members" {
  for_each = {
    for membership in local.sp_memberships :
    "${membership.group_key}-${membership.sp_name}" => membership
  }

  group_id  = databricks_group.groups[each.value.group_key].id
  member_id = each.value.sp_id

  depends_on = [databricks_group.groups]
}

# Add groups to groups (nested membership)
resource "databricks_group_member" "group_members" {
  for_each = {
    for membership in local.group_memberships :
    "${membership.parent_group_key}-${membership.nested_group_name}" => membership
  }

  group_id  = databricks_group.groups[each.value.parent_group_key].id
  member_id = each.value.nested_group_id

  depends_on = [databricks_group.groups]
}