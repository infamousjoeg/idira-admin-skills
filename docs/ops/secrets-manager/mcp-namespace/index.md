# Mcp Namespace

**Area:** `secrets-manager`  ·  **Kind:** tf/secrets-manager/mcp-namespace

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

## Local prerequisite — Terraform version

This module pins `cyberark/conjur >= 0.8.4`. Terraform **1.5.7** has trouble installing this version (provider-publishing metadata isn't recognized — likely signing-key chain mismatch). **Use Terraform 1.6 or newer.** Update via `brew upgrade terraform` (if you accept the BUSL-1.1 license) or use OpenTofu (`brew install opentofu`) which is API-compatible.

## Caveats

- **`-parallelism=1` may be required** for the first apply. Per the provider's [Best Practices](https://registry.terraform.io/providers/cyberark/conjur/latest/docs), Secrets Manager doesn't allow simultaneous policy loads under the same branch. Our `depends_on` chain should serialize the four resources correctly, but if you hit a `409 Conflict`, retry with `terraform apply -parallelism=1`.
- **`conjur_group` is write-only.** Per the provider docs, group state isn't tracked precisely — changes outside Terraform (e.g., via `conjur policy load`) can cause drift. Re-running this module is safe but won't reconcile a manually-edited group.
- **Privileges granted are on the policy branch itself**, not on individual secrets. This is broader than per-secret grants and matches Joe's "MCP user can access everything under the MCP server" intent. For finer-grained access, grant per-variable permissions in a downstream module.
- **Identity user IDs.** Identity users authenticate via OAuth2 and are auto-provisioned in Conjur with their email as the resource ID — no `data/` prefix (per memory entry: "Conjur Cloud user ID format for Identity-synced users"). Set `initial_user_email = "user@your-tenant.cyberark.cloud"`.


## Adapting for your tenant

# Adapting `tf/secrets-manager/mcp-namespace/` for your tenant

For AI agents helping a user apply this module on a tenant other than `infamous`.

## Before you apply

Verify the parent branches exist:

```bash
conjur list --kind policy --search "data/mcp" 2>&1 | head -5
# Expect: data/mcp, data/mcp/server, data/mcp/user
```

If not, run the one-time bootstrap from the README BEFORE applying this module. Otherwise the first `terraform apply` will fail with `422 Unprocessable Entity`.

## Variables the user must set

- **`mcp_name`** — the slug for the new MCP. Derive kebab-case from any human name the user gives.

## Variables to verify, not assume

- **`initial_user_email`** — if the user mentions a person who should have access, set this to their Identity user email. The format is `<localpart>@<tenant-subdomain>.cyberark.cloud` for tenants on the default Identity domain, or `<localpart>@<custom-domain>` for tenants with vanity domains.
- **`privileges`** — default `["read", "execute"]` gives the user group read access to the policy + execute (decrypt) on any secrets in the namespace. If the user wants the group to be able to load additional policy under the namespace, add `"update"`.

## Variables tenant-specific in subtle ways

- **`parent_server_branch` / `parent_user_branch`** — default to Joe's convention. Some tenants may have their MCP root branches elsewhere (e.g., `data/applications/mcp/server`). Ask the user only if their org has documented a different convention.

## Things baked in that might not generalize

- The convention `data/mcp/server/<n>` + `data/mcp/user/<n>` is Joe's. Many orgs flatten this to a single `data/mcp/<n>` branch with sub-policies. If the user pushes back on the two-branch structure, this module isn't the right fit; capture a new one with their preferred shape.

## Verification after apply

1. `terraform output server_branch_id` → confirm the path looks right.
2. `conjur list --kind policy --search "$(terraform output -raw server_branch_id)"` → should show the namespace.
3. `conjur show "$(terraform output -raw user_group_id)"` → should show the group, with the initial user listed under `members` if you set `initial_user_email`.

## Common errors

- **`422 Unprocessable Entity` on first apply** → parent branches don't exist. Bootstrap first.
- **`409 Conflict`** → simultaneous policy load attempt. Retry with `terraform apply -parallelism=1`.
- **`404 Not Found` on the `initial_user` membership** → the Identity user email is wrong, or your `CONJUR_AUTHN_LOGIN` doesn't have membership-management privilege on that group.

