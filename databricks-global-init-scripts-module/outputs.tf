output "init_scripts" {
  description = "Created global init scripts with their details"
  value = merge(
    {
      for k, v in databricks_global_init_script.direct_scripts : k => {
        id       = v.id
        name     = v.name
        enabled  = v.enabled
        position = v.position
        source   = "direct_content"
      }
    },
    {
      for k, v in databricks_global_init_script.dbfs_scripts : k => {
        id       = v.id
        name     = v.name
        enabled  = v.enabled
        position = v.position
        source   = v.source
      }
    }
  )
}

output "init_script_ids" {
  description = "Map of script keys to their IDs"
  value = merge(
    {
      for k, v in databricks_global_init_script.direct_scripts : k => v.id
    },
    {
      for k, v in databricks_global_init_script.dbfs_scripts : k => v.id
    }
  )
}

output "dbfs_files" {
  description = "Created DBFS files with their details"
  value = merge(
    {
      for k, v in databricks_dbfs_file.init_script_files : "${k}_script" => {
        id        = v.id
        path      = v.path
        dbfs_path = v.dbfs_path
        file_size = v.file_size
      }
    },
    {
      for k, v in databricks_dbfs_file.additional_files : k => {
        id        = v.id
        path      = v.path
        dbfs_path = v.dbfs_path
        file_size = v.file_size
      }
    }
  )
}

output "dbfs_file_paths" {
  description = "Map of file keys to their DBFS paths"
  value = merge(
    {
      for k, v in databricks_dbfs_file.init_script_files : "${k}_script" => v.dbfs_path
    },
    {
      for k, v in databricks_dbfs_file.additional_files : k => v.dbfs_path
    }
  )
}