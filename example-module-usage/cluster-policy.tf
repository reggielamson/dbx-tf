module "cluster_policy_example1" {
  source = "../databricks-cluster-policy-module"

  policies = {
    "security-policy" = {
      name        = "High Security Policy"
      description = "Enforces security best practices"
      policy_type = "security"

      allowed_instance_types = ["m5.large", "m5.xlarge"]
      enable_ssh_public_keys = false

      permissions = {
        access_control_list = [
          {
            group_name       = "security-admins"
            permission_level = "CAN_USE"
          },
          {
            group_name       = "data-engineers"
            permission_level = "CAN_USE"
          }
        ]
      }
    }
  }
}

module "cluster_policies_example2" {
  source = "../databricks-cluster-policy-module"

  common_settings = {
    default_auto_termination_minutes = 90
    organization_required_tags = {
      "managed-by" = "terraform"
      "owner"      = "data-team"
    }
  }

  policies = {
    "dev-policy" = {
      name                     = "Development Policy"
      policy_type              = "cost_control"
      auto_termination_minutes = 30
      max_workers             = 5
    }

    "prod-policy" = {
      name                = "Production Policy"
      policy_type         = "security"
      max_workers         = 50
      force_auto_termination = false

      permissions = {
        access_control_list = [
          {
            group_name       = "production-users"
            permission_level = "CAN_USE"
          }
        ]
      }
    }
  }
}