# Create cluster policies
resource "databricks_cluster_policy" "policies" {
  for_each = local.processed_policies

  name       = each.value.name
  definition = jsonencode(each.value.policy_definition)

  depends_on = []
}

# Set permissions on cluster policies
resource "databricks_permissions" "cluster_policy_permissions" {
  for_each = {
    for policy_key, policy in var.policies : policy_key => policy
    if policy.permissions != null
  }

  cluster_policy_id = databricks_cluster_policy.policies[each.key].id

  dynamic "access_control" {
    for_each = each.value.permissions.access_control_list
    content {
      user_name              = access_control.value.user_name
      group_name             = access_control.value.group_name
      service_principal_name = access_control.value.service_principal_name
      permission_level       = access_control.value.permission_level
    }
  }

  depends_on = [databricks_cluster_policy.policies]
}