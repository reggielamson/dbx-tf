output "cluster_policies" {
  description = "Created cluster policies with their IDs and details"
  value = {
    for k, v in databricks_cluster_policy.policies : k => {
      id         = v.id
      name       = v.name
      definition = v.definition
    }
  }
}

output "policy_ids" {
  description = "Map of policy names to their IDs"
  value = {
    for k, v in databricks_cluster_policy.policies : k => v.id
  }
}

output "policy_definitions" {
  description = "The processed policy definitions (for debugging)"
  value = {
    for k, v in local.processed_policies : k => v.policy_definition
  }
  sensitive = false
}