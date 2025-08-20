# Configure GitHub integration (if provided)
resource "databricks_workspace_conf" "github_config" {
  count = var.github_configuration != null ? 1 : 0

  custom_config = local.github_config
}

# Configure general workspace settings (if provided)
resource "databricks_workspace_conf" "workspace_config" {
  count = length(var.workspace_configuration) > 0 ? 1 : 0

  custom_config = var.workspace_configuration
}

# Configure workspace entitlements for each principal (if provided)
resource "databricks_entitlements" "workspace_entitlements" {
  for_each = local.filtered_entitlements

  # Set the principal ID based on type
  user_id              = each.value.principal_type == "user" ? each.value.principal_id : null
  group_id             = each.value.principal_type == "group" ? each.value.principal_id : null
  service_principal_id = each.value.principal_type == "service_principal" ? each.value.principal_id : null

  # Set entitlements
  allow_cluster_create       = lookup(each.value.entitlements, "allow_cluster_create", null)
  allow_instance_pool_create = lookup(each.value.entitlements, "allow_instance_pool_create", null)
  databricks_sql_access      = lookup(each.value.entitlements, "databricks_sql_access", null)
  workspace_access           = lookup(each.value.entitlements, "workspace_access", null)
}

# Configure group IAM roles
resource "databricks_group_role" "iam_roles" {
  for_each = local.iam_roles

  group_id = each.value.group_id
  role     = each.value.iam_role_arn
}

# Configure group instance profiles
resource "databricks_group_role" "instance_profiles" {
  for_each = local.instance_profiles

  group_id = each.value.group_id
  role     = each.value.instance_profile_arn
}

# Create service tokens
resource "databricks_token" "service_tokens" {
  for_each = var.service_tokens

  comment          = each.value.comment
  lifetime_seconds = each.value.lifetime_seconds
}

# Set permissions on tokens (using authorization = "tokens")
resource "databricks_permissions" "token_permissions" {
  count = length(var.service_tokens) > 0 ? 1 : 0

  authorization = "tokens"

  dynamic "access_control" {
    for_each = local.token_permissions
    content {
      user_name              = access_control.value.user_name
      group_name             = access_control.value.group_name
      service_principal_name = access_control.value.service_principal_name
      permission_level       = access_control.value.permission_level
    }
  }

  depends_on = [databricks_token.service_tokens]
}