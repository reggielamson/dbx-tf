module "databricks_init_scripts" {
  source = "../databricks-global-init-scripts-module"

  init_scripts = {
    "security-setup" = {
      name        = "Security Configuration"
      enabled     = true
      position    = 1
      source_file = "${path.module}/global_init_scripts/test1.sh"
    }

    "monitoring-agent" = {
      name        = "Install Monitoring Agent"
      enabled     = true
      position    = 10
      source_file = "${path.module}/global_init_scripts/test2.sh"
    }
  }
}