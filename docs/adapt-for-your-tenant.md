---
title: Adapt for your tenant
description: Use this project on your own Idira tenant by pointing your AI agent (Claude Code, Cursor, Codex) at the AGENTS.md guidance per op.
---

# Adapt for your tenant

This catalog was built originally for one tenant (`infamous`). Every captured op is designed so you (and your AI agent) can adapt it to *your* tenant by changing a small, well-marked set of variables.

## The two-file pattern

Every Terraform module (`tf/<area>/<op>/`) and every script (`scripts/<area>/<op>/`) ships with two files specifically for adaptation:

- **`README.md`** — for humans. Explains what the op does, when to use it, and what the variables mean.
- **`AGENTS.md`** — for your AI agent. Lists every value that's tenant-specific, what to ask the user about, what to leave at default, and how to verify after apply.

Point Claude Code / Cursor / Codex at the per-op `AGENTS.md` along with the root `AGENTS.md` in the repo. The agent will know exactly what to do.

## The fast path

Suppose you cloned the repo and want to adopt the `tf/identity/oauth-webapp-pkce/` op for your tenant `acme`.

```bash
# 1. Auth + discovery
export CYBERARK_TENANT_SUBDOMAIN=acme
# (configure CYBERARK_AUTH_PROVIDER + credential refs per Get started)

# 2. Ask your AI agent to adapt the module
#    Prompt: "Apply tf/identity/oauth-webapp-pkce/ for my tenant, creating an app named 'my-app'."
```

Your agent will:
1. Read `tf/identity/oauth-webapp-pkce/AGENTS.md`.
2. Apply Joe's defaults except where you've overridden (e.g., your callback URI).
3. Run `lib/tf-wrap.sh apply tf/identity/oauth-webapp-pkce/` with your tfvars.
4. Show you the plan, prompt for confirmation, apply.

## What you'll typically need to change

| What | Where | Why |
|---|---|---|
| Tenant subdomain | `$CYBERARK_TENANT_SUBDOMAIN` env var | Resolved through Platform Discovery — never hardcoded |
| Service User credentials | Your secret store (set via `$CYBERARK_AUTH_PROVIDER` + provider-specific env vars) | Each tenant has its own credentials |
| Callback URLs | `var.redirect_uri` in OAuth webapp modules | Your apps run at your URLs |
| Resource names | `var.app_name`, `var.safe_name`, etc. | Your naming conventions |
| Secrets Manager branch convention | `var.branch_path` defaults to `data/` | If your tenant uses a non-default policy organization |

## What you *shouldn't* change (without security review)

- `var.pkce_required` defaults to `true` for OAuth webapps. PKCE is the modern public-client OAuth best practice; lowering this opens the door to authorization-code interception. Don't disable unless you have a non-PKCE use case that's been reviewed.
- `var.confidential` defaults to `false` for OAuth webapps intended for public clients (CLIs, MCPs, native apps). Setting it `true` requires you to store a `client_secret` somewhere — which you almost certainly don't want in client config files.
- The Secrets Manager MCP-namespace convention (`data/mcp/server/<name>` + `data/mcp/user/<name>`) is opinionated for clean audit trails. Override only if you have a specific organizational policy that conflicts.

## Adding a new op to your fork

If your tenant requires an op that isn't in the catalog yet:

1. Ask your AI agent to do it ad-hoc (with the plugin or repo loaded — see Get started).
2. The agent will write a draft to `_inbox/<timestamp>-<slug>/`.
3. Run `/ca-promote` to review and land it in `tf/<area>/<op>/` or `scripts/<area>/<op>/`.
4. Either keep it private to your fork, or open a PR upstream to share with the community.

Upstream PRs are welcomed especially for:
- Ops covering services we haven't touched yet (e.g., ITDR, DPA/JIT, SCA, Discovery & Context, Session Monitoring).
- Better idempotency in existing ops.
- Better `AGENTS.md` adaptation guidance.

See [CONTRIBUTING.md](https://github.com/infamousjoeg/idira-admin-skills/blob/main/CONTRIBUTING.md) on the repo for PR conventions.
