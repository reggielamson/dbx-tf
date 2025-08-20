variable "init_scripts" {
  description = "Map of global init scripts to create"
  type = map(object({
    name        = string
    enabled     = optional(bool, true)
    position    = optional(number, 10)

    # Script content options (choose one)
    content     = optional(string)           # Direct script content
    source_file = optional(string)           # Local file path

    # DBFS file options (alternative to content/source_file)
    use_dbfs_file = optional(bool, false)
    dbfs_path     = optional(string)         # DBFS path where script will be stored

    # File upload options (when use_dbfs_file = true)
    file_content      = optional(string)     # Content to upload to DBFS
    file_source       = optional(string)     # Local file to upload to DBFS
    file_content_b64  = optional(string)     # Base64 encoded content
  }))
  default = {}

  validation {
    condition = alltrue([
      for script_key, script in var.init_scripts :
      (script.content != null && script.source_file == null && !script.use_dbfs_file) ||
      (script.content == null && script.source_file != null && !script.use_dbfs_file) ||
      (script.content == null && script.source_file == null && script.use_dbfs_file && script.dbfs_path != null)
    ])
    error_message = "Each script must specify exactly one content source: 'content', 'source_file', or 'use_dbfs_file' with 'dbfs_path'."
  }

  validation {
    condition = alltrue([
      for script_key, script in var.init_scripts :
      !script.use_dbfs_file || (
        (script.file_content != null && script.file_source == null && script.file_content_b64 == null) ||
        (script.file_content == null && script.file_source != null && script.file_content_b64 == null) ||
        (script.file_content == null && script.file_source == null && script.file_content_b64 != null)
      )
    ])
    error_message = "When use_dbfs_file is true, specify exactly one of: 'file_content', 'file_source', or 'file_content_b64'."
  }
}

variable "additional_dbfs_files" {
  description = "Additional DBFS files to upload (not used as init scripts)"
  type = map(object({
    path              = string
    content           = optional(string)
    source            = optional(string)
    content_b64       = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for file_key, file in var.additional_dbfs_files :
      (file.content != null && file.source == null && file.content_b64 == null) ||
      (file.content == null && file.source != null && file.content_b64 == null) ||
      (file.content == null && file.source == null && file.content_b64 != null)
    ])
    error_message = "Each DBFS file must specify exactly one content source: 'content', 'source', or 'content_b64'."
  }
}

variable "default_script_position" {
  description = "Default position for init scripts"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# modules/databricks-global-init-scripts/locals.tf

locals {
  # Scripts that use direct content or local files
  direct_scripts = {
    for script_key, script in var.init_scripts : script_key => script
    if !script.use_dbfs_file
  }

  # Scripts that use DBFS files
  dbfs_scripts = {
    for script_key, script in var.init_scripts : script_key => script
    if script.use_dbfs_file
  }

  # Prepare script content for direct scripts
  direct_script_content = {
    for script_key, script in local.direct_scripts : script_key => (
      script.content != null ? script.content : file(script.source_file)
    )
  }

  # Prepare DBFS file content for scripts
  dbfs_script_files = {
    for script_key, script in local.dbfs_scripts : script_key => {
      path    = script.dbfs_path
      content = script.file_content != null ? script.file_content : (
        script.file_source != null ? file(script.file_source) : null
      )
      content_b64 = script.file_content_b64
    }
  }

  # Prepare additional DBFS files content
  additional_dbfs_content = {
    for file_key, file in var.additional_dbfs_files : file_key => {
      path    = file.path
      content = file.content != null ? file.content : (
        file.source != null ? file(file.source) : null
      )
      content_b64 = file.content_b64
    }
  }
}