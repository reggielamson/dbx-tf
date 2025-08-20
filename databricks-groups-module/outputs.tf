output "groups" {
  description = "Created groups with their IDs and details"
  value = {
    for k, v in databricks_group.groups : k => {
      id           = v.id
      display_name = v.display_name
      external_id  = v.external_id
    }
  }
}

output "group_ids" {
  description = "Map of group keys to their IDs"
  value = {
    for k, v in databricks_group.groups : k => v.id
  }
}

output "workspace_assignments" {
  description = "Summary of workspace assignments"
  value = {
    for k, v in databricks_mws_permission_assignment.group_workspace_assignments : k => {
      group_id     = v.principal_id
      workspace_id = v.workspace_id
      permissions  = v.permissions
    }
  }
}

output "group_memberships" {
  description = "Summary of all group memberships"
  value = {
    user_memberships = {
      for k, v in databricks_group_member.user_members : k => {
        group_id  = v.group_id
        member_id = v.member_id
      }
    }
    sp_memberships = {
      for k, v in databricks_group_member.sp_members : k => {
        group_id  = v.group_id
        member_id = v.member_id
      }
    }
    group_memberships = {
      for k, v in databricks_group_member.group_members : k => {
        group_id  = v.group_id
        member_id = v.member_id
      }
    }
  }
}