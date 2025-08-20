output "workspace" {
  description = "Created workspace details"
  value = var.enable_workspace_creation ? {
    workspace_id    = databricks_mws_workspaces.workspace[0].workspace_id
    workspace_name  = databricks_mws_workspaces.workspace[0].workspace_name
    deployment_name = databricks_mws_workspaces.workspace[0].deployment_name
    workspace_url   = databricks_mws_workspaces.workspace[0].workspace_url
    aws_region      = databricks_mws_workspaces.workspace[0].aws_region
    pricing_tier    = databricks_mws_workspaces.workspace[0].pricing_tier
  } : {
    workspace_id = var.existing_workspace_id
    workspace_name = "existing"
    deployment_name = "existing"
    workspace_url = null
    aws_region = var.workspace.aws_region
    pricing_tier = var.workspace.pricing_tier
  }
}

output "workspace_id" {
  description = "Workspace ID"
  value       = local.workspace_id
}

output "workspace_url" {
  description = "Workspace URL"
  value       = var.enable_workspace_creation ? databricks_mws_workspaces.workspace[0].workspace_url : null
}

output "credentials" {
  description = "Created credentials configuration"
  value = {
    credentials_id   = databricks_mws_credentials.credentials.credentials_id
    credentials_name = databricks_mws_credentials.credentials.credentials_name
    role_arn        = databricks_mws_credentials.credentials.role_arn
  }
}

output "storage_configuration" {
  description = "Created storage configuration"
  value = {
    storage_configuration_id   = databricks_mws_storage_configurations.storage.storage_configuration_id
    storage_configuration_name = databricks_mws_storage_configurations.storage.storage_configuration_name
    bucket_name               = databricks_mws_storage_configurations.storage.bucket_name
  }
}

output "network_configuration" {
  description = "Created network configuration (if any)"
  value = local.network_config != null ? {
    network_id   = databricks_mws_networks.network[0].network_id
    network_name = databricks_mws_networks.network[0].network_name
    vpc_id       = databricks_mws_networks.network[0].vpc_id
    subnet_ids   = databricks_mws_networks.network[0].subnet_ids
  } : null
}

output "customer_managed_key" {
  description = "Created customer managed key configuration (if any)"
  value = local.cmk_config != null ? {
    customer_managed_key_id = databricks_mws_customer_managed_keys.cmk[0].customer_managed_key_id
    key_arn                = databricks_mws_customer_managed_keys.cmk[0].aws_key_info[0].key_arn
    key_alias              = databricks_mws_customer_managed_keys.cmk[0].aws_key_info[0].key_alias
  } : null
}

output "metastore_assignment" {
  description = "Metastore assignment details (if any)"
  value = var.metastore_assignment != null ? {
    workspace_id         = length(databricks_metastore_assignment.metastore) > 0 ? databricks_metastore_assignment.metastore[0].workspace_id : null
    metastore_id        = length(databricks_metastore_assignment.metastore) > 0 ? databricks_metastore_assignment.metastore[0].metastore_id : null
    default_catalog_name = length(databricks_metastore_assignment.metastore) > 0 ? databricks_metastore_assignment.metastore[0].default_catalog_name : null
  } : null
}

output "ip_access_lists" {
  description = "Created IP access lists"
  value = {
    for k, v in databricks_ip_access_list.access_lists : k => {
      id           = v.id
      label        = v.label
      list_type    = v.list_type
      ip_addresses = v.ip_addresses
      enabled      = v.enabled
    }
  }
}

output "workspace_configuration" {
  description = "Applied workspace configuration"
  value = length(var.workspace_configuration) > 0 ? {
    custom_config = length(databricks_workspace_conf.workspace_config) > 0 ? databricks_workspace_conf.workspace_config[0].custom_config : var.workspace_configuration
  } : null
}