# `tf/secrets-manager/mcp-namespace/` — per-MCP namespace on Secrets Manager

Creates a per-MCP namespace pair on Secrets Manager (formerly Conjur Cloud), following the convention from `~/Documents/Projects/panw/memory/cyberark-tenant.md`:

- `data/mcp/server/<mcp_name>` — the workload/secret namespace (where this MCP's secrets live)
- `data/mcp/user/<mcp_name>` — the user namespace (where the MCP's users + groups live)
- A `users` group inside the user namespace
- A `read + execute` permission grant linking the group to the server namespace
- (Optionally) an initial Identity user added to the group

## Prerequisites

The parent branches `data/mcp/server` and `data/mcp/user` **must already exist** on your tenant. Bootstrap them with one of:

```bash
# Option A — one-time TF apply (a future tf/secrets-manager/mcp-root/ module — not yet captured):
# tf/secrets-manager/mcp-root/

# Option B — manual policy load:
cat > /tmp/mcp-root.yml <<'YAML'
- !policy
  id: mcp
  body:
  - !policy { id: server }
  - !policy { id: user }
YAML
conjur policy load --branch data --file /tmp/mcp-root.yml
```

After this one-time setup, the per-MCP module is fully self-contained.

## When to use

Prompt patterns that route here:
- *"Create the Secrets Manager namespace for a new MCP called &lt;name&gt;"*
- *"Set up Conjur policy for the &lt;name&gt; MCP"*
- *"Provision the data/mcp/server and data/mcp/user branches for &lt;name&gt;"*

## Variables

| Name | Type | Default | Required |
|---|---|---|---|
| `mcp_name` | `string` | — | ✅ |
| `parent_server_branch` | `string` | `"data/mcp/server"` | |
| `parent_user_branch` | `string` | `"data/mcp/user"` | |
| `group_name` | `string` | `"users"` | |
| `privileges` | `list(string)` | `["read", "execute"]` | |
| `initial_user_email` | `string` | `null` | |
| `annotations` | `map(string)` | `{}` | |

## Outputs

- `server_branch_id` — e.g., `data/mcp/server/witty-muffin`
- `user_branch_id` — e.g., `data/mcp/user/witty-muffin`
- `user_group_id` — e.g., `data/mcp/user/witty-muffin/users`
- `granted_privileges`, `initial_user_email` — passthroughs

## Example

```bash
cp examples/default/terraform.tfvars.example terraform.tfvars
# edit mcp_name + (optional) initial_user_email
$REPO/lib/tf-wrap.sh apply tf/secrets-manager/mcp-namespace
```

## Local prerequisite — `tofu` (OpenTofu) recommended

This module pins `cyberark/conjur >= 0.8.4`. **Terraform 1.5.7** (the last MPL-2.0 release in Homebrew) can't install that version. Either:

- Install **OpenTofu** (recommended — MPL-2.0, drop-in compatible): `brew install opentofu`, then use `tofu` instead of `terraform`. `lib/tf-wrap.sh` auto-detects either binary.
- Install Terraform 1.6+ directly from HashiCorp (BUSL 1.1).

## Caveats

### `tofu validate` doesn't work — but `plan` and `apply` do

The provider's `ValidateConfig` checks attribute values against the raw config (AST) instead of the resolved variable values. So `branch = var.parent_server_branch` is seen as "empty" during `validate`, even with a default. **This is a provider-side quirk, not a bug in this module** — hardcoded values pass validate fine.

Skip `tofu validate` for this module. The module IS correct: `tofu plan` resolves variables before sending to the provider, so plan + apply work. `lib/tf-wrap.sh apply` is the canonical entry point.

- **`-parallelism=1` may be required** for the first apply. Per the provider's [Best Practices](https://registry.terraform.io/providers/cyberark/conjur/latest/docs), Secrets Manager doesn't allow simultaneous policy loads under the same branch. Our `depends_on` chain should serialize the four resources correctly, but if you hit a `409 Conflict`, retry with `terraform apply -parallelism=1`.
- **`conjur_group` is write-only.** Per the provider docs, group state isn't tracked precisely — changes outside Terraform (e.g., via `conjur policy load`) can cause drift. Re-running this module is safe but won't reconcile a manually-edited group.
- **Privileges granted are on the policy branch itself**, not on individual secrets. This is broader than per-secret grants and matches Joe's "MCP user can access everything under the MCP server" intent. For finer-grained access, grant per-variable permissions in a downstream module.
- **Identity user IDs.** Identity users authenticate via OAuth2 and are auto-provisioned in Conjur with their email as the resource ID — no `data/` prefix (per memory entry: "Conjur Cloud user ID format for Identity-synced users"). Set `initial_user_email = "user@your-tenant.cyberark.cloud"`.
