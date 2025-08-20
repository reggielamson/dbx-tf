module "databricks_workspace_config_basic" {
  source = "../databricks-workspace-configuration-module"

  # General workspace settings
  workspace_configuration = {
    "enableIpAccessLists"     = "true"
    "enableTokensConfig"      = "true"
    "maxTokenLifetimeDays"    = "90"
    "enableWebTerminal"       = "true"
    "enableResultsDownloading" = "false"
  }

  # Workspace entitlements for specific principals
  workspace_entitlements = {
    "data-engineers-group" = {
      principal_type              = "group"
      principal_id               = "group-id-1234"
      allow_cluster_create       = true
      allow_instance_pool_create = true
      databricks_sql_access      = true
      workspace_access           = true
    }
  }
}

module "databricks_workspace_config_github" {
  source = "../databricks-workspace-configuration-module"

  # GitHub integration
  github_configuration = {
    personal_access_token = var.github_pat
    git_username         = "databricks-service"
    git_provider         = "gitHub"
  }

  workspace_configuration = {
    "enableGitVersioning" = "true"
    "gitIntegrationEnabled" = "true"
  }
}