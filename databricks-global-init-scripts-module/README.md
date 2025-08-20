# Databricks Global Init Scripts Module

This Terraform module creates and manages Databricks global init scripts with support for multiple content sources and DBFS file management. It's designed to be error-free and avoids the type consistency issues common in complex Terraform configurations.

## Features

- Create global init scripts with multiple content sources
- Support for direct content, local files, and DBFS files
- Upload additional DBFS files for libraries, configs, etc.
- Configurable script positioning and enablement
- Base64 encoding support for binary files
- Comprehensive validation to prevent configuration errors
- Clean separation between different script types

## Content Source Options

### 1. Direct Content
Provide script content directly in the configuration:
```hcl
content = "#!/bin/bash\necho 'Hello World'"
```

### 2. Local File
Reference a local file to upload:
```hcl
source_file = "${path.module}/scripts/init.sh"
```

### 3. DBFS File
Upload to DBFS first, then reference in init script:
```hcl
use_dbfs_file = true
dbfs_path = "/databricks/init_scripts/my_script.sh"
file_content = "#!/bin/bash\necho 'Hello from DBFS'"
```

## Usage Examples

### Basic Init Scripts with Direct Content

```hcl
module "databricks_init_scripts" {
  source = "./modules/databricks-global-init-scripts"

  init_scripts = {
    "install-packages" = {
      name     = "Install Common Packages"
      enabled  = true
      position = 1
      content  = <<-EOF
        #!/bin/bash
        apt-get update
        apt-get install -y htop curl wget
        pip install pandas numpy
      EOF
    }

    "setup-logging" = {
      name     = "Setup Logging Configuration"
      enabled  = true
      position = 5
      content  = <<-EOF
        #!/bin/bash
        mkdir -p /var/log/custom
        echo "Setting up custom logging..."
      EOF
    }
  }
}
```

### Using Local Files

```hcl
module "databricks_init_scripts" {
  source = "./modules/databricks-global-init-scripts"

  init_scripts = {
    "security-setup" = {
      name        = "Security Configuration"
      enabled     = true
      position    = 1
      source_file = "${path.module}/scripts/security_init.sh"
    }

    "monitoring-agent" = {
      name        = "Install Monitoring Agent"
      enabled     = true
      position    = 10
      source_file = "${path.module}/scripts/monitoring.sh"
    }
  }
}
```

### Using DBFS Files

```hcl
module "databricks_init_scripts" {
  source = "./modules/databricks-global-init-scripts"

  init_scripts = {
    "custom-driver-setup" = {
      name          = "Custom Driver Setup"
      enabled       = true
      position      = 5
      use_dbfs_file = true
      dbfs_path     = "/databricks/init_scripts/driver_setup.sh"
      file_source   = "${path.module}/scripts/driver_init.sh"
    }

    "worker-config" = {
      name          = "Worker Node Configuration"
      enabled       = true
      position      = 8
      use_dbfs_file = true
      dbfs_path     = "/databricks/init_scripts/worker_config.sh"
      file_content  = <<-EOF
        #!/bin/bash
        echo "Configuring worker nodes..."
        # Worker-specific setup
      EOF
    }
  }
}
```

### Mixed Content Sources with Additional Files

```hcl
module "databricks_init_scripts" {
  source = "./modules/databricks-global-init-scripts"

  init_scripts = {
    # Direct content
    "quick-setup" = {
      name     = "Quick Environment Setup"
      enabled  = true
      position = 1
      content  = "#!/bin/bash\necho 'Quick setup complete'"
    }

    # Local file
    "security-hardening" = {
      name        = "Security Hardening"
      enabled     = true
      position    = 3
      source_file = "${path.module}/scripts/security.sh"
    }

    # DBFS file
    "custom-libraries" = {
      name          = "Install Custom Libraries"
      enabled       = true
      position      = 5
      use_dbfs_file = true
      dbfs_path     = "/databricks/init_scripts/libraries.sh"
      file_source   = "${path.module}/scripts/install_libs.sh"
    }
  }

  # Additional files for libraries, configs, etc.
  additional_dbfs_files = {
    "custom-config" = {
      path    = "/databricks/configs/app.conf"
      source  = "${path.module}/configs/app.conf"
    }

    "python-requirements" = {
      path    = "/databricks/configs/requirements.txt"
      content = <<-EOF
        pandas==1.5.0
        numpy==1.24.0
        scikit-learn==1.1.0
      EOF
    }

    "binary-driver" = {
      path        = "/databricks/drivers/custom_driver.jar"
      content_b64 = filebase64("${path.module}/drivers/custom_driver.jar")
    }
  }
}
```

### Environment-Specific Scripts

```hcl
module "databricks_init_scripts" {
  source = "./modules/databricks-global-init-scripts"

  init_scripts = {
    "environment-setup" = {
      name     = "Environment Setup - ${var.environment}"
      enabled  = var.environment != "dev"  # Disable in dev
      position = 1
      content  = templatefile("${path.module}/scripts/env_setup.sh.tpl", {
        environment = var.environment
        log_level   = var.environment == "prod" ? "ERROR" : "DEBUG"
      })
    }

    "monitoring" = {
      name        = "Monitoring Agent"
      enabled     = contains(["staging", "prod"], var.environment)
      position    = 10
      source_file = "${path.module}/scripts/monitoring_${var.environment}.sh"
    }
  }

  additional_dbfs_files = {
    "env-config" = {
      path    = "/databricks/configs/${var.environment}.conf"
      content = templatefile("${path.module}/configs/app.conf.tpl", {
        environment = var.environment
        api_url     = var.api_urls[var.environment]
      })
    }
  }

  default_script_position = 10
}
```

### Complex Multi-Script Setup

```hcl
module "databricks_init_scripts" {
  source = "./modules/databricks-global-init-scripts"

  init_scripts = {
    # System-level setup (runs first)
    "system-setup" = {
      name     = "System Configuration"
      enabled  = true
      position = 1
      content  = file("${path.module}/scripts/01_system.sh")
    }

    # Security setup
    "security" = {
      name          = "Security Configuration"
      enabled       = true
      position      = 2
      use_dbfs_file = true
      dbfs_path     = "/databricks/init_scripts/security.sh"
      file_source   = "${path.module}/scripts/02_security.sh"
    }

    # Network configuration
    "network" = {
      name        = "Network Setup"
      enabled     = var.enable_custom_networking
      position    = 3
      source_file = "${path.module}/scripts/03_network.sh"
    }

    # Application dependencies
    "dependencies" = {
      name          = "Install Dependencies"
      enabled       = true
      position      = 5
      use_dbfs_file = true
      dbfs_path     = "/databricks/init_scripts/dependencies.sh"
      file_content  = templatefile("${path.module}/scripts/dependencies.sh.tpl", {
        python_packages = var.python_packages
        system_packages = var.system_packages
      })
    }

    # Final validation
    "validation" = {
      name     = "Setup Validation"
      enabled  = true
      position = 99
      content  = <<-EOF
        #!/bin/bash
        echo "Validating cluster setup..."
        python -c "import pandas, numpy; print('Python packages OK')"
        echo "All init scripts completed successfully"
      EOF
    }
  }

  additional_dbfs_files = {
    # Configuration files
    "app-config" = {
      path   = "/databricks/configs/application.yaml"
      source = "${path.module}/configs/app.yaml"
    }

    # Custom Python modules
    "custom-module" = {
      path        = "/databricks/python/custom_utils.py"
      source      = "${path.module}/python/custom_utils.py"
    }

    # Binary dependencies
    "native-lib" = {
      path        = "/databricks/lib/native_lib.so"
      content_b64 = filebase64("${path.module}/lib/native_lib.so")
    }
  }

  default_script_position = 10
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| init_scripts | Map of global init scripts to create | `map(object)` | `{}` | no |
| additional_dbfs_files | Additional DBFS files to upload | `map(object)` | `{}` | no |
| default_script_position | Default position for init scripts | `number` | `10` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Init Script Object Structure

Each script in `init_scripts` supports:

**Basic Properties:**
- `name` (required): Script display name
- `enabled` (optional, default: true): Whether script is enabled
- `position` (optional, default: 10): Script execution order

**Content Sources (choose one):**
- `content`: Direct script content as string
- `source_file`: Path to local file
- `use_dbfs_file`: Use DBFS file (requires `dbfs_path`)

**DBFS File Options (when `use_dbfs_file = true`):**
- `dbfs_path` (required): DBFS path for the script
- `file_content`: Content to upload to DBFS
- `file_source`: Local file to upload to DBFS  
- `file_content_b64`: Base64 encoded content

## Additional DBFS File Object Structure

Each file in `additional_dbfs_files` supports:
- `path` (required): DBFS path for the file
- `content`: File content as string
- `source`: Path to local file
- `content_b64`: Base64 encoded content
- `overwrite` (optional, default: true): Whether to overwrite existing files

## Outputs

| Name | Description |
|------|-------------|
| init_scripts | Created global init scripts with details |
| init_script_ids | Map of script keys to their IDs |
| dbfs_files | Created DBFS files with details |
| dbfs_file_paths | Map of file keys to their DBFS paths |

## Design Principles

This module follows these principles to avoid common Terraform errors:

1. **Clear Separation**: Different content sources are handled separately
2. **Type Consistency**: All conditionals return consistent types
3. **Comprehensive Validation**: Prevents invalid configurations upfront
4. **Simple Logic**: Avoids complex merge operations
5. **Predictable Structure**: Consistent patterns for all operations

## File Organization Best Practices

```
├── modules/
│   └── databricks-global-init-scripts/
│       ├── main.tf
│       ├── variables.tf
│       ├── locals.tf
│       ├── outputs.tf
│       └── README.md
├── scripts/
│   ├── 01_system.sh
│   ├── 02_security.sh
│   ├── 03_network.sh
│   └── dependencies.sh.tpl
├── configs/
│   ├── app.yaml
│   └── app.conf.tpl
└── python/
    └── custom_utils.py
```

This module provides a robust, error-free way to manage Databricks global init scripts and DBFS files with multiple content sources and comprehensive validation.