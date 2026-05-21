# mcp-namespace — Promotion Notes

## What this does

Creates the per-MCP namespace pair (`data/mcp/server/<n>` + `data/mcp/user/<n>`), a `users` group under the user namespace, and a permission grant linking them — encoding the MCP convention from `~/Documents/Projects/panw/memory/cyberark-tenant.md`.

## Defaults applied without asking

- `parent_server_branch = "data/mcp/server"` (per memory convention)
- `parent_user_branch = "data/mcp/user"` (per memory convention)
- `group_name = "users"`
- `privileges = ["read", "execute"]`
- Group is granted on the **policy branch** (`kind = "policy"`), not per-secret — coarse but matches the intent
- All branches/groups get `idira-admin-skills/role = <role>` annotation for provenance

## What worked / what didn't

**Worked:** All four resources (policy_branch x2, group, permission) using the documented schemas. `depends_on` chain serializes correctly per provider Best Practices.

**Didn't (yet):**
- `data/mcp/server` and `data/mcp/user` must already exist. We chose NOT to create them in this module to keep the per-MCP module idempotent across multiple invocations. The bootstrap pattern is documented in README — to be captured as `tf/secrets-manager/mcp-root/` in a follow-up.
- The `conjur_group` resource is documented as "write-only — import and exact state tracking not supported due to API limitations." This means drift detection on groups is limited; manual changes via `conjur policy load` won't show up in `terraform plan`. Acceptable for now.

## Suggested catalog placement

`tf/secrets-manager/mcp-namespace/` (already here).

## Suggested SKILL.md description

Use when a user wants to provision a Secrets Manager (formerly Conjur Cloud) namespace for a new MCP — creates `data/mcp/server/<name>`, `data/mcp/user/<name>`, a `users` group, and a permission grant. Encodes the convention documented in [[cyberark-tenant]]. Requires the `data/mcp/server` and `data/mcp/user` parent branches to already exist (bootstrap separately). Routes to this module via `lib/tf-wrap.sh apply tf/secrets-manager/mcp-namespace`. Sets sensible defaults; allows initial Identity user assignment via `initial_user_email`.
