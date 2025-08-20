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