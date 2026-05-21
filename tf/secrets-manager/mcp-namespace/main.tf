################################################################################
# tf/secrets-manager/mcp-namespace — per-MCP namespace under data/mcp/
#
# Creates the two policy branches that hold an MCP's workload + user identities
# (data/mcp/server/<n> and data/mcp/user/<n>), a `users` group under the user
# namespace, and a permission grant linking that group to the server namespace.
#
# Prerequisites: data/mcp/server and data/mcp/user must already exist on the
# tenant. Bootstrap once via tf/secrets-manager/mcp-root/ (forthcoming) or
# manually via `conjur policy load --branch data --file mcp-root.yml`.
#
# Provider auth: cyberark/conjur reads CONJUR_APPLIANCE_URL, CONJUR_ACCOUNT,
# CONJUR_AUTHN_LOGIN, CONJUR_AUTHN_API_KEY from env. lib/auth.sh populates
# these from the conjur CLI session + the discovered SECRETS_MANAGER_API_URL.
################################################################################

# Per-MCP workload namespace: data/mcp/server/<mcp_name>
resource "conjur_policy_branch" "server" {
  branch      = var.parent_server_branch
  name        = var.mcp_name
  annotations = merge({ "idira-admin-skills/role" = "mcp-server" }, var.annotations)
}

# Per-MCP user namespace: data/mcp/user/<mcp_name>
resource "conjur_policy_branch" "user" {
  branch      = var.parent_user_branch
  name        = var.mcp_name
  annotations = merge({ "idira-admin-skills/role" = "mcp-user" }, var.annotations)
}

# Users group inside the per-MCP user namespace
resource "conjur_group" "users" {
  branch      = conjur_policy_branch.user.full_id
  name        = var.group_name
  annotations = merge({ "idira-admin-skills/role" = "mcp-user-group" }, var.annotations)

  depends_on = [conjur_policy_branch.user]
}

# Grant the user group privileges on the server policy branch.
# The "policy" kind here refers to the conjur_policy_branch resource itself —
# granting privileges on the policy effectively grants access to everything under it.
resource "conjur_permission" "users_on_server" {
  role = {
    name   = conjur_group.users.name
    kind   = "group"
    branch = conjur_policy_branch.user.full_id
  }

  resource = {
    name   = conjur_policy_branch.server.name
    kind   = "policy"
    branch = var.parent_server_branch
  }

  privileges = var.privileges

  depends_on = [
    conjur_policy_branch.server,
    conjur_group.users,
  ]
}

# Optional: add an initial Identity user to the group.
# Identity users authenticate via OAuth2 and are auto-provisioned in Conjur on
# first auth, so the email need not already exist as a Conjur resource.
resource "conjur_membership" "initial_user" {
  count = var.initial_user_email == null ? 0 : 1

  group_id    = conjur_group.users.id == null ? "${conjur_policy_branch.user.full_id}/${conjur_group.users.name}" : "${conjur_policy_branch.user.full_id}/${conjur_group.users.name}"
  member_kind = "user"
  member_id   = var.initial_user_email

  depends_on = [conjur_group.users]
}
