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
