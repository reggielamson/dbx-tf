variable "workspace" {
  description = "Workspace configuration"
  type = object({
    workspace_name    = string
    deployment_name   = optional(string)
    aws_region        = string
    account_id        = string

    # Pricing tier
    pricing_tier = optional(string, "PREMIUM")

    # Tags
    custom_tags = optional(map(string), {})
  })

  validation {
    condition     = contains(["STANDARD", "PREMIUM", "ENTERPRISE"], var.workspace.pricing_tier)
    error_message = "Pricing tier must be STANDARD, PREMIUM, or ENTERPRISE."
  }
}

variable "credentials" {
  description = "AWS credentials configuration"
  type = object({
    credentials_name = string
    role_arn        = string
  })
}

variable "storage_configuration" {
  description = "Storage configuration for the workspace"
  type = object({
    storage_configuration_name = string
    bucket_name               = string
  })
}

variable "network_configuration" {
  description = "Network configuration (optional)"
  type = object({
    network_name       = string
    vpc_id            = string
    subnet_ids        = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "customer_managed_key" {
  description = "Customer managed key configuration (optional)"
  type = object({
    key_alias      = string
    key_arn        = string
    key_region     = optional(string)
    use_cases      = optional(list(string), ["MANAGED_SERVICES"])
  })
  default = null

  validation {
    condition = var.customer_managed_key == null || alltrue([
      for use_case in var.customer_managed_key.use_cases :
      contains(["MANAGED_SERVICES", "STORAGE"], use_case)
    ])
    error_message = "Use cases must be 'MANAGED_SERVICES' and/or 'STORAGE'."
  }
}

variable "metastore_assignment" {
  description = "Unity Catalog metastore assignment (optional)"
  type = object({
    metastore_id           = string
    default_catalog_name   = optional(string, "main")
  })
  default = null
}

variable "ip_access_lists" {
  description = "IP access lists configuration"
  type = map(object({
    label       = string
    list_type   = string  # ALLOW or BLOCK
    ip_addresses = optional(list(string), [])
    enabled     = optional(bool, true)
  }))
  default = {}

  validation {
    condition = alltrue([
      for key, config in var.ip_access_lists :
      contains(["ALLOW", "BLOCK"], config.list_type)
    ])
    error_message = "IP access list type must be ALLOW or BLOCK."
  }
}

variable "workspace_configuration" {
  description = "Workspace configuration settings"
  type = map(string)
  default = {}
}

variable "enable_workspace_creation" {
  description = "Whether to create the workspace (useful for managing existing workspaces)"
  type        = bool
  default     = true
}

variable "existing_workspace_id" {
  description = "Existing workspace ID (when enable_workspace_creation = false)"
  type        = string
  default     = null
}

# modules/databricks-workspace/locals.tf

locals {
  # Determine workspace ID - either from created workspace or existing
  workspace_id = var.enable_workspace_creation ? (
    length(databricks_mws_workspaces.workspace) > 0 ? databricks_mws_workspaces.workspace[0].workspace_id : null
  ) : var.existing_workspace_id

  # Prepare network configuration if provided
  network_config = var.network_configuration != null ? {
    network_name       = var.network_configuration.network_name
    vpc_id            = var.network_configuration.vpc_id
    subnet_ids        = var.network_configuration.subnet_ids
    security_group_ids = var.network_configuration.security_group_ids
  } : null

  # Prepare CMK configuration if provided
  cmk_config = var.customer_managed_key != null ? {
    key_alias  = var.customer_managed_key.key_alias
    key_arn    = var.customer_managed_key.key_arn
    key_region = coalesce(var.customer_managed_key.key_region, var.workspace.aws_region)
    use_cases  = var.customer_managed_key.use_cases
  } : null

  # Workspace tags
  workspace_tags = merge(
    {
      "Environment" = "managed-by-terraform"
    },
    var.workspace.custom_tags
  )
}