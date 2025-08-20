# Upload DBFS files for init scripts
resource "databricks_dbfs_file" "init_script_files" {
  for_each = local.dbfs_script_files

  path = each.value.path
  content_base64 = each.value.content_b64 != null ? each.value.content_b64 : base64encode(each.value.content)
}

# Upload additional DBFS files
resource "databricks_dbfs_file" "additional_files" {
  for_each = local.additional_dbfs_content

  path = each.value.path
  content_base64 = each.value.content_b64 != null ? each.value.content_b64 : base64encode(each.value.content)
}

# Create global init scripts using direct content
resource "databricks_global_init_script" "direct_scripts" {
  for_each = local.direct_scripts

  name     = each.value.name
  enabled  = each.value.enabled
  position = coalesce(each.value.position, var.default_script_position)
  content_base64 = base64encode(local.direct_script_content[each.key])
}

# Create global init scripts using DBFS files
resource "databricks_global_init_script" "dbfs_scripts" {
  for_each = local.dbfs_scripts

  name     = each.value.name
  enabled  = each.value.enabled
  position = coalesce(each.value.position, var.default_script_position)
  source   = databricks_dbfs_file.init_script_files[each.key].dbfs_path

  depends_on = [databricks_dbfs_file.init_script_files]
}