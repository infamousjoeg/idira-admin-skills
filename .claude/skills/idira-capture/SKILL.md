---
name: idira-capture
description: Use after any successful ad-hoc administration operation against an Idira tenant when no matching Terraform module or script existed beforehand. Drafts the operation's exact code, output, and adaptation notes to _inbox/<timestamp>-<slug>/ so the human can later review and promote it into the permanent catalog via /ca-promote.
---

# Idira Capture

Your job: take a successful ad-hoc op and write a *draft* of what would make it reusable. The human will review and finalize via `/ca-promote`. **Do not perfect the draft. Do not place it in the permanent catalog. Do not commit.**

## When to invoke

- A `terraform apply` (inline TF) succeeded for a request that didn't have a matching module in `tf/<area>/<op>/`.
- An `ark exec ...` succeeded for a request that didn't have a matching script in `scripts/<area>/<op>/`.
- A `conjur <subcommand>` succeeded similarly.
- A raw `curl` against an Idira API succeeded similarly.

**Don't invoke for:**
- Pure reads / `terraform plan`-only / listing operations (these don't change state and don't need to be captured).
- Operations that re-ran an existing captured module/script (those are already in the catalog).

## What to write

Create the directory `_inbox/$(date -u +%Y-%m-%d-%H%M)-<descriptive-slug>/` with:

### `inline.tf` (if Terraform was used)

The exact `.tf` you ran, parameterized to the best of your ability. Variables should:
- Replace tenant-specific values with `var.<n>` references
- Default to Joe's `infamous`-tenant values
- Use Idira/CyberArk-correct types (`string`, `list(string)`, `bool`, etc.)
- Include a `description` on each variable

Include a `versions.tf` that pins the provider:

```hcl
terraform {
  required_version = ">= 1.6"
  required_providers {
    idsec = {
      source  = "cyberark/idsec"
      version = "~> 0.3"
    }
  }
}
```

### `run.sh` (if `ark` / `conjur` / raw REST was used)

The exact command(s) you ran, in a portable bash script. Header:

```bash
#!/usr/bin/env bash
# RISK: read|mutate|destructive
# DESCRIPTION: <one-line summary>
set -euo pipefail
source "$(git rev-parse --show-toplevel)/lib/auth.sh"
```

Parameterize tenant-specific values as positional args or `${VAR:-default}` substitutions. Make idempotent where possible (check before create, etc.).

### `SKILL_NOTES.md`

What was done, in plain prose. Cover:

```markdown
# <Op Title> — Capture Notes

## What this does
<2-3 sentences>

## What I assumed (defaults applied without asking)
- callback URL: `http://localhost:3000/callback`
- scope: `api`
- PKCE: required
- (etc — only the non-trivial ones)

## What worked / what didn't
<note any quirks the human should know about — e.g., "the docs say X but the API returns Y", or "first attempt failed because Z">

## Suggested catalog placement
`tf/<area>/<op-slug>/` or `scripts/<area>/<op-slug>/`

## Suggested skill summary
<a one-paragraph SKILL.md description that would let a future router pick this op>
```

### `AGENTS.md`

For other AI agents adapting this op to a different tenant. Flag every value that needs review:

```markdown
# Adapting <op> for your tenant

## Variables you must change
- `var.app_name` — name of the OAuth webapp
- `var.redirect_uri` — your MCP / app callback (default works for local MCP dev)

## Variables you might change
- `var.scopes` — defaults to `["api"]`; adjust for your tenant's OAuth2 scopes
- `var.pkce_required` — defaults to `true`; do not lower without security review

## Tenant-specific assumptions baked in
- (list anything tenant-specific that isn't already a variable)

## Verification
After apply, the op did X / created resource Y / returned ID Z. To verify in your tenant: <how>
```

## What NOT to include in the draft

- Real `client_id` / `client_secret` / `access_token` values — even truncated. Reference Conceal paths or secret-store paths only.
- The brand PPTX or any extracted Idira logos.
- Tenant-specific tfvars in the root of the draft (put example tfvars under `examples/` only).
- `.terraform/` or `terraform.tfstate*` — gitignored.

## After writing the draft

Print a one-line confirmation to the user:

> ✓ Captured to `_inbox/<dirname>/`. Run `/ca-promote` later to review and land in the catalog.

Do not auto-run `/ca-promote`. The human decides when to triage the inbox.
