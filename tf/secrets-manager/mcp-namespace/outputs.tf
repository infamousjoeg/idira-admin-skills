output "server_branch_id" {
  description = "Full Conjur policy ID of the per-MCP server (workload) namespace. Use this as the branch path when adding workload identities or secrets, e.g., `data/mcp/server/witty-muffin`."
  value       = conjur_policy_branch.server.full_id
}

output "user_branch_id" {
  description = "Full Conjur policy ID of the per-MCP user namespace, e.g., `data/mcp/user/witty-muffin`."
  value       = conjur_policy_branch.user.full_id
}

output "user_group_id" {
  description = "Full Conjur ID of the user group (defaults to `data/mcp/user/<mcp_name>/users`). Members of this group inherit the privileges granted to the server namespace."
  value       = "${conjur_policy_branch.user.full_id}/${conjur_group.users.name}"
}

output "granted_privileges" {
  description = "Privileges granted to the user group on the server namespace."
  value       = var.privileges
}

output "initial_user_email" {
  description = "Initial Identity user added to the group on first apply, if any."
  value       = var.initial_user_email
}
