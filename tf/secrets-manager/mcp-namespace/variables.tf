variable "mcp_name" {
  description = "Slug for this MCP — used as the leaf name under `data/mcp/server/<mcp_name>` and `data/mcp/user/<mcp_name>`. Kebab-case, lowercased."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,62}[a-z0-9]$", var.mcp_name))
    error_message = "mcp_name must be 3-64 chars, kebab-case, start with a letter and end with a letter or digit."
  }
}

variable "parent_server_branch" {
  description = "Parent branch under which the per-MCP server namespace is created. Joe's convention: `data/mcp/server`. **Must already exist** — bootstrap with `tf/secrets-manager/mcp-root/` (forthcoming) or one-time manual policy load."
  type        = string
  default     = "data/mcp/server"
}

variable "parent_user_branch" {
  description = "Parent branch under which the per-MCP user namespace is created. Joe's convention: `data/mcp/user`. Same prerequisite as `parent_server_branch`."
  type        = string
  default     = "data/mcp/user"
}

variable "group_name" {
  description = "Name of the user group created under the per-MCP user branch. Members of this group are granted access to the server namespace."
  type        = string
  default     = "users"
}

variable "privileges" {
  description = "Privileges the user group is granted on the server policy branch. Defaults to `[read, execute]` — read the policy itself + execute any secrets under it. Add `update` if the group should be able to load policy."
  type        = list(string)
  default     = ["read", "execute"]

  validation {
    condition     = length(var.privileges) > 0
    error_message = "At least one privilege must be granted."
  }
}

variable "initial_user_email" {
  description = "Optional Identity user email to add to the group on first apply (e.g., `joegarcia@infamous.dev`). When null, no initial user is added — use `conjur_membership` separately to add members later. Identity users are auto-provisioned on first auth, so the email need not already exist in Conjur."
  type        = string
  default     = null
}

variable "annotations" {
  description = "Map of annotations applied to all created policy branches (both server and user). Useful for environment/owner/cost-center tagging."
  type        = map(string)
  default     = {}
}
