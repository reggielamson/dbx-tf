# Create AWS credentials configuration
resource "databricks_mws_credentials" "credentials" {
  account_id       = var.workspace.account_id
  credentials_name = var.credentials.credentials_name
  role_arn        = var.credentials.role_arn
}

# Create storage configuration
resource "databricks_mws_storage_configurations" "storage" {
  account_id                 = var.workspace.account_id
  storage_configuration_name = var.storage_configuration.storage_configuration_name
  bucket_name               = var.storage_configuration.bucket_name
}

# Create network configuration (if provided)
resource "databricks_mws_networks" "network" {
  count = local.network_config != null ? 1 : 0

  account_id   = var.workspace.account_id
  network_name = local.network_config.network_name
  vpc_id       = local.network_config.vpc_id
  subnet_ids   = local.network_config.subnet_ids
  security_group_ids = local.network_config.security_group_ids
}

# Create customer managed key configuration (if provided)
resource "databricks_mws_customer_managed_keys" "cmk" {
  count = local.cmk_config != null ? 1 : 0

  account_id = var.workspace.account_id
  use_cases  = local.cmk_config.use_cases

  aws_key_info {
    key_arn    = local.cmk_config.key_arn
    key_alias  = local.cmk_config.key_alias
    key_region = local.cmk_config.key_region
  }
}

# Create workspace
resource "databricks_mws_workspaces" "workspace" {
  count = var.enable_workspace_creation ? 1 : 0

  account_id      = var.workspace.account_id
  workspace_name  = var.workspace.workspace_name
  deployment_name = var.workspace.deployment_name
  aws_region      = var.workspace.aws_region
  pricing_tier    = var.workspace.pricing_tier

  credentials_id           = databricks_mws_credentials.credentials.credentials_id
  storage_configuration_id = databricks_mws_storage_configurations.storage.storage_configuration_id

  # Optional configurations
  network_id                = local.network_config != null ? databricks_mws_networks.network[0].network_id : null
  customer_managed_key_id   = local.cmk_config != null ? databricks_mws_customer_managed_keys.cmk[0].customer_managed_key_id : null

  custom_tags = local.workspace_tags

  depends_on = [
    databricks_mws_credentials.credentials,
    databricks_mws_storage_configurations.storage
  ]
}

# Assign metastore to workspace (if provided)
resource "databricks_metastore_assignment" "metastore" {
  count = var.metastore_assignment != null ? 1 : 0

  workspace_id         = local.workspace_id
  metastore_id        = var.metastore_assignment.metastore_id
  default_catalog_name = var.metastore_assignment.default_catalog_name

  depends_on = [databricks_mws_workspaces.workspace]
}

# Configure IP access lists
resource "databricks_ip_access_list" "access_lists" {
  for_each = var.ip_access_lists

  label        = each.value.label
  list_type    = each.value.list_type
  ip_addresses = each.value.ip_addresses
  enabled      = each.value.enabled

  depends_on = [databricks_mws_workspaces.workspace]
}

# Configure workspace settings
resource "databricks_workspace_conf" "workspace_config" {
  count = length(var.workspace_configuration) > 0 ? 1 : 0

  custom_config = var.workspace_configuration

  depends_on = [databricks_mws_workspaces.workspace]
}