module "databricks_workspace" {
  source = "../databricks-workspace-module"

  workspace = {
    workspace_name  = "enterprise-databricks-workspace"
    deployment_name = "enterprise-deployment"
    aws_region     = "us-east-1"
    account_id     = "123456789012"
    pricing_tier   = "ENTERPRISE"

    custom_tags = {
      Environment = "production"
      Team        = "data-platform"
      CostCenter  = "engineering"
      Owner       = "data-team@company.com"
    }
  }

  credentials = {
    credentials_name = "databricks-enterprise-role"
    role_arn        = "arn:aws:iam::123456789012:role/databricks-enterprise-role"
  }

  storage_configuration = {
    storage_configuration_name = "enterprise-workspace-storage"
    bucket_name               = "enterprise-databricks-workspace-bucket"
  }

  # VPC configuration for network isolation
  network_configuration = {
    network_name       = "databricks-enterprise-network"
    vpc_id            = "vpc-12345678"
    subnet_ids        = ["subnet-12345678", "subnet-87654321"]
    security_group_ids = ["sg-12345678"]
  }

  # Customer managed encryption
  customer_managed_key = {
    key_alias  = "databricks-workspace-key"
    key_arn    = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    key_region = "us-east-1"
    use_cases  = ["MANAGED_SERVICES", "STORAGE"]
  }

  # Unity Catalog integration
  metastore_assignment = {
    metastore_id         = "metastore-12345678-1234-1234-1234-123456789012"
    default_catalog_name = "main"
  }

  # IP access control
  ip_access_lists = {
    "corporate-network" = {
      label        = "Corporate Network Access"
      list_type    = "ALLOW"
      ip_addresses = ["10.0.0.0/8", "192.168.1.0/24"]
      enabled      = true
    }

    "blocked-regions" = {
      label        = "Blocked Geographic Regions"
      list_type    = "BLOCK"
      ip_addresses = ["203.0.113.0/24"]
      enabled      = true
    }
  }

  # Workspace configuration
  workspace_configuration = {
    "enableIpAccessLists"                    = "true"
    "enableTokensConfig"                     = "true"
    "maxTokenLifetimeDays"                   = "90"
    "enableDeprecatedClusterNamedInitScripts" = "false"
    "enableDeprecatedGlobalInitScripts"      = "false"
    "enableWebTerminal"                      = "true"
    "enableResultsDownloading"               = "true"
  }
}