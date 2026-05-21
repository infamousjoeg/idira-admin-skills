---
name: secrets-manager-mcp-namespace
description: Use when the user wants to provision a Secrets Manager namespace for a new MCP — creates the data/mcp/server/<name> + data/mcp/user/<name> branches, a users group, and a permission grant linking them. Encodes Joe's MCP convention from [[cyberark-tenant]]. Requires the data/mcp/server and data/mcp/user parent branches to already exist (bootstrap separately or via the README's one-time policy load).
---

# secrets-manager-mcp-namespace — Per-MCP namespace on Secrets Manager

Use this skill when the user wants a Secrets Manager (formerly Conjur Cloud) namespace pair set up for an MCP. Typical triggers:

- "Create the Secrets Manager namespace for a new MCP called &lt;name&gt;"
- "Set up Conjur policy for &lt;name&gt; MCP"
- "Provision data/mcp/server/&lt;name&gt; and data/mcp/user/&lt;name&gt;"

**Don't use this skill for:**
- Creating individual secrets, hosts, or workloads — those need a downstream module (`tf/secrets-manager/host/` or `tf/secrets-manager/secret/`, forthcoming).
- Granting access to a single existing variable — use a more targeted `conjur_permission` capture.
- Loading raw Conjur policy YAML — use the `conjur` CLI directly (or capture a script).

## Pre-flight check

Before applying, verify the parent branches exist:

```bash
$REPO/lib/ark-wrap.sh ...  # (no ark equivalent for Secrets Manager)
conjur list --kind policy --search "data/mcp" | head -5
```

Expected: `data/mcp`, `data/mcp/server`, `data/mcp/user`.

If missing, run the one-time bootstrap from the module README BEFORE applying this module. Don't auto-bootstrap silently — surface it to the user with the snippet from the README so they can confirm.

## How to invoke

1. Extract `mcp_name` from the user's request — kebab-case slug. Validate against `^[a-z][a-z0-9-]{1,62}[a-z0-9]$`.
2. If the user mentions a person who should have access, capture their Identity user email as `initial_user_email`. Otherwise leave null.
3. Write `terraform.tfvars` from `examples/default/terraform.tfvars.example`. Edit `mcp_name`.
4. Run `lib/tf-wrap.sh apply tf/secrets-manager/mcp-namespace`.
5. If you see `409 Conflict` on first try, retry with `-parallelism=1` (the wrapper accepts `-parallelism=1` as an arg).
6. Print the outputs (`server_branch_id`, `user_branch_id`, `user_group_id`).

## Idempotency

Re-running with the same `mcp_name` is a no-op IF the resources weren't modified outside Terraform. The `conjur_group` resource has limited drift detection (write-only per provider docs) — if a user manually edited the group via `conjur policy load`, this module won't reconcile.

## If the user wants something this doesn't cover

- **Different naming convention** (e.g., `data/applications/<n>` instead of `data/mcp/`): set `parent_server_branch` and `parent_user_branch` accordingly. Then capture as a new variant or rename this module.
- **Granular per-secret permissions**: this module grants group access on the entire server policy branch. For per-variable grants, use a separate `conjur_permission` capture.
- **Loading initial secrets into the namespace**: separate concern — use the `conjur` CLI directly with `conjur variable set` after apply, or capture a downstream TF module.
