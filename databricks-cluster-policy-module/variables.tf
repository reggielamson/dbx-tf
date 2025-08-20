variable "policies" {
  description = "Map of cluster policies to create"
  type = map(object({
    name        = string
    description = optional(string, "Cluster policy managed by Terraform")

    # Policy type - determines which preset to use
    policy_type = optional(string, "custom")  # custom, cost_control, security, data_engineering, ml_workload

    # Custom policy definition (JSON string or map)
    policy_definition = optional(any, {})

    # Common policy settings (used when policy_type != "custom")
    max_cluster_count = optional(number)

    # Node type restrictions
    allowed_instance_types = optional(list(string))
    denied_instance_types  = optional(list(string))

    # Size restrictions
    min_workers = optional(number)
    max_workers = optional(number)

    # Driver restrictions
    allowed_driver_instance_types = optional(list(string))
    denied_driver_instance_types  = optional(list(string))

    # Databricks runtime restrictions
    allowed_runtime_versions = optional(list(string))
    denied_runtime_versions  = optional(list(string))

    # Auto-termination
    auto_termination_minutes = optional(number)
    force_auto_termination   = optional(bool, false)

    # Autoscaling
    enable_autoscaling = optional(bool)

    # Spot instances
    allow_spot_instances = optional(bool)
    spot_bid_max_percent = optional(number)

    # Security settings
    enable_local_disk_encryption = optional(bool)
    enable_cluster_log_conf      = optional(bool)

    # Custom tags to enforce
    required_tags = optional(map(string), {})

    # Init scripts
    allowed_init_script_paths = optional(list(string))
    required_init_scripts     = optional(list(string))

    # SSH settings
    enable_ssh_public_keys = optional(bool, false)

    # Libraries
    allowed_libraries = optional(list(string))
    denied_libraries  = optional(list(string))

    # Advanced settings
    enable_elastic_disk = optional(bool)
    preloaded_spark_packages = optional(list(string))

    # Permission settings
    permissions = optional(object({
      access_control_list = optional(list(object({
        user_name              = optional(string)
        group_name             = optional(string)
        service_principal_name = optional(string)
        permission_level       = string  # CAN_USE
      })), [])
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for policy_key, policy in var.policies :
      contains(["custom", "cost_control", "security", "data_engineering", "ml_workload"], policy.policy_type)
    ])
    error_message = "Policy type must be one of: custom, cost_control, security, data_engineering, ml_workload."
  }
}

variable "default_tags" {
  description = "Default tags to apply to all policies"
  type        = map(string)
  default     = {}
}

variable "common_settings" {
  description = "Common settings to apply to all policies of specific types"
  type = object({
    default_auto_termination_minutes = optional(number, 120)
    default_spark_version           = optional(string)
    organization_required_tags      = optional(map(string), {})
  })
  default = {}
}

# modules/databricks-cluster-policy/locals.tf

locals {
  # Predefined policy templates
  policy_templates = {
    cost_control = {
      "autotermination_minutes" = {
        "type" = "range"
        "maxValue" = var.common_settings.default_auto_termination_minutes
        "defaultValue" = var.common_settings.default_auto_termination_minutes
      }
      "custom_tags.cost-center" = {
        "type" = "fixed"
        "value" = "required"
        "hidden" = false
      }
    }

    security = {
      "enable_local_disk_encryption" = {
        "type" = "fixed"
        "value" = true
        "hidden" = true
      }
      "ssh_public_keys" = {
        "type" = "forbidden"
        "hidden" = true
      }
      "enable_elastic_disk" = {
        "type" = "fixed"
        "value" = false
        "hidden" = true
      }
    }

    data_engineering = {
      "autotermination_minutes" = {
        "type" = "range"
        "minValue" = 30
        "maxValue" = 480
        "defaultValue" = 120
      }
      "autoscale.min_workers" = {
        "type" = "range"
        "minValue" = 1
        "maxValue" = 10
      }
      "autoscale.max_workers" = {
        "type" = "range"
        "minValue" = 1
        "maxValue" = 50
      }
    }

    ml_workload = {
      "node_type_id" = {
        "type" = "allowlist"
        "values" = ["i3.xlarge", "i3.2xlarge", "i3.4xlarge"]
      }
      "driver_node_type_id" = {
        "type" = "allowlist"
        "values" = ["i3.xlarge", "i3.2xlarge", "i3.4xlarge"]
      }
      "enable_elastic_disk" = {
        "type" = "fixed"
        "value" = true
        "hidden" = true
      }
    }
  }

  # Build custom policy rules for each policy
  custom_policy_rules = {
    for policy_key, policy in var.policies : policy_key => merge(
      # Auto-termination rules
      policy.auto_termination_minutes != null ? {
        "autotermination_minutes" = policy.force_auto_termination ? {
          "type" = "fixed"
          "value" = policy.auto_termination_minutes
          "hidden" = true
        } : {
          "type" = "range"
          "maxValue" = policy.auto_termination_minutes
          "defaultValue" = policy.auto_termination_minutes
        }
      } : {},

      # Worker count rules
      policy.min_workers != null || policy.max_workers != null ? {
        "num_workers" = {
          "type" = "range"
          "minValue" = coalesce(policy.min_workers, 1)
          "maxValue" = coalesce(policy.max_workers, 100)
        }
      } : {},

      # Autoscaling rules
      policy.enable_autoscaling == true && (policy.min_workers != null || policy.max_workers != null) ? {
        "autoscale.min_workers" = {
          "type" = "range"
          "minValue" = coalesce(policy.min_workers, 1)
          "maxValue" = coalesce(policy.max_workers, 100)
        }
        "autoscale.max_workers" = {
          "type" = "range"
          "minValue" = coalesce(policy.min_workers, 1)
          "maxValue" = coalesce(policy.max_workers, 100)
        }
      } : {},

      # Instance type allow rules
      length(coalesce(policy.allowed_instance_types, [])) > 0 ? {
        "node_type_id" = {
          "type" = "allowlist"
          "values" = policy.allowed_instance_types
        }
      } : {},

      # Instance type deny rules
      length(coalesce(policy.denied_instance_types, [])) > 0 ? {
        "node_type_id" = {
          "type" = "blocklist"
          "values" = policy.denied_instance_types
        }
      } : {},

      # Driver instance type allow rules
      length(coalesce(policy.allowed_driver_instance_types, [])) > 0 ? {
        "driver_node_type_id" = {
          "type" = "allowlist"
          "values" = policy.allowed_driver_instance_types
        }
      } : {},

      # Driver instance type deny rules
      length(coalesce(policy.denied_driver_instance_types, [])) > 0 ? {
        "driver_node_type_id" = {
          "type" = "blocklist"
          "values" = policy.denied_driver_instance_types
        }
      } : {},

      # Runtime version allow rules
      length(coalesce(policy.allowed_runtime_versions, [])) > 0 ? {
        "spark_version" = {
          "type" = "allowlist"
          "values" = policy.allowed_runtime_versions
        }
      } : {},

      # Runtime version deny rules
      length(coalesce(policy.denied_runtime_versions, [])) > 0 ? {
        "spark_version" = {
          "type" = "blocklist"
          "values" = policy.denied_runtime_versions
        }
      } : {},

      # Security rules
      policy.enable_local_disk_encryption == true ? {
        "enable_local_disk_encryption" = {
          "type" = "fixed"
          "value" = true
          "hidden" = true
        }
      } : {},

      # Spot instance rules
      policy.allow_spot_instances != null ? {
        "aws_attributes.availability" = policy.allow_spot_instances ? {
          "type" = "allowlist"
          "values" = ["SPOT", "ON_DEMAND"]
        } : {
          "type" = "fixed"
          "value" = "ON_DEMAND"
          "hidden" = true
        }
      } : {},

      # Spot bid percentage rules
      policy.spot_bid_max_percent != null ? {
        "aws_attributes.spot_bid_price_percent" = {
          "type" = "range"
          "maxValue" = policy.spot_bid_max_percent
        }
      } : {},

      # SSH public keys
      policy.enable_ssh_public_keys == false ? {
        "ssh_public_keys" = {
          "type" = "forbidden"
          "hidden" = true
        }
      } : {},

      # Elastic disk
      policy.enable_elastic_disk != null ? {
        "enable_elastic_disk" = {
          "type" = "fixed"
          "value" = policy.enable_elastic_disk
          "hidden" = true
        }
      } : {},

      # Required tags
      length(policy.required_tags) > 0 ? {
        for tag_key, tag_value in policy.required_tags :
        "custom_tags.${tag_key}" => {
          "type" = "fixed"
          "value" = tag_value
          "hidden" = false
        }
      } : {},

      # Organization required tags
      length(var.common_settings.organization_required_tags) > 0 ? {
        for tag_key, tag_value in var.common_settings.organization_required_tags :
        "custom_tags.${tag_key}" => {
          "type" = "fixed"
          "value" = tag_value
          "hidden" = false
        }
      } : {}
    )
  }

  # Build policy definitions for each policy
  processed_policies = {
    for policy_key, policy in var.policies : policy_key => {
      name        = policy.name
      description = policy.description
      policy_definition = merge(
        # Start with custom rules (always present)
        local.custom_policy_rules[policy_key],
        # Add template rules if not custom policy
        policy.policy_type != "custom" ? local.policy_templates[policy.policy_type] : {},
        # Add custom policy definition last (highest priority)
        policy.policy_type == "custom" ? policy.policy_definition : {}
      )
      permissions = policy.permissions
    }
  }
}