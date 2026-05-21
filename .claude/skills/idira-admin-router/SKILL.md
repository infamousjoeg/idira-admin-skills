---
name: idira-admin-router
description: Use when the user asks you to administer their Idira (CyberArk Identity Security Platform) tenant — creating, updating, listing, or deleting Identity webapps, users, roles, policies; Privilege Cloud accounts, safes, target platforms; Secrets Manager (Conjur Cloud) policies, hosts, groups, secrets; SIA connectors and settings; Secrets Hub sync policies; Connector Manager pools; and Unified Access Policies. Routes the request through the appropriate tool (Terraform module → ark CLI → conjur CLI → raw REST) and ensures the successful path is auto-captured for reuse.
---

# Idira Admin Router

You are administering a tenant on the CyberArk Identity Security Platform (marketed as **Idira by Palo Alto Networks**). Pick the best tool, run the op idempotently, and auto-draft the successful path for later promotion to the permanent catalog.

## The selection order — try in this order, stop at the first match

### 1. Existing Terraform module in `tf/<area>/<op>/`

Run `ls tf/<area>/` to see what's already captured. If a module fits the user's request:
- Read the module's `variables.tf` and `examples/*/terraform.tfvars` to understand what vars it takes.
- Construct a `terraform.tfvars` for the current request (use Joe's defaults from `CLAUDE.md` — `infamous` subdomain, `http://localhost:3000/callback`, PKCE required, `data/mcp/server/<n>` convention, etc.).
- Invoke `lib/tf-wrap.sh <area>/<op>` which handles `init`, `plan`, prompt-for-confirmation, `apply`, and audit logging.

### 2. No module yet — write inline TF using one of the three providers

The CyberArk-published providers cover ~80% of admin surface area:

| Provider | Covers |
|---|---|
| `cyberark/idsec` (v0.3.3+) | Identity (users, roles, **webapps incl. PKCE OAuth**, policies, auth profiles, role members, attributes); Privilege Cloud (accounts, safes, applications, target platforms); SIA (access connectors, relays, certificates, db/secrets, ~30 settings); CMGR (networks, pools); CCE (cloud orgs/accounts/subscriptions); access policies (cloud_access, db, group_access, vm) |
| `cyberark/conjur` (v0.8.4+) | Secrets Manager — policy_branch, host, group, secret, permission, membership, authenticator |
| `cyberark/cyberark` (v0.3.9+) | Secrets Hub (sync_policy, secret_store_* for AWS/Azure/GCP); PAM Self-Hosted via PVWA (accounts, safe, db_account) |

If your request maps to a resource in one of these, write the inline TF in `_inbox/<UTC-timestamp>-<slug>/inline.tf`. Use the provider's docs at `https://registry.terraform.io/providers/cyberark/<provider>/latest/docs/resources/<resource>`. Run via `lib/tf-wrap.sh _inbox/<timestamp>-<slug>/`.

### 3. No TF coverage — use the `ark` CLI

The `ark` CLI (`pip install ark-sdk-python`) covers procedural operations across the platform. Command shape:

```bash
ark exec <service> <subgroup> <action> [flags]
```

Services: `identity`, `pcloud`, `sia`, `sm` (session monitoring), `cmgr`, `uap`. Wrap via `lib/ark-wrap.sh` which ensures the user's Service User profile is loaded and the right discovered URL is targeted.

### 4. `ark` doesn't cover Secrets Manager — use the `conjur` CLI

The `ark` CLI doesn't cover Secrets Manager (formerly Conjur Cloud). For SM ops not handled by `cyberark/conjur` TF provider, use the `conjur` CLI directly. The user's CLI is already initialized (`~/.conjurrc`) and logged in via Service User.

### 5. Last resort — raw REST

Mint a token via `lib/auth.sh mint-identity-token`, target the appropriate API URL from the Platform Discovery cache (`cache/discovery-<subdomain>.json`), and curl. Flag this in the `AGENTS.md` of the captured script — these should be migrated to TF or `ark` as soon as coverage exists.

## After a successful operation

If the operation was an ad-hoc one (no matching module/script existed before), invoke the `idira-capture` skill to write a draft to `_inbox/`. Do not promote the draft yourself — that's the human's call via `/ca-promote`.

Always append an audit entry to `audit/$(date -u +%Y-%m-%d).jsonl` with JSON shape:

```json
{"ts": "2026-05-20T14:23:01Z", "op": "create-identity-webapp", "tool": "terraform:cyberark/idsec", "params": {...}, "result": "applied", "subdomain": "infamous"}
```

## Autonomy defaults (don't ask the user — apply and note)

- OAuth webapp callback: `http://localhost:3000/callback`
- OAuth scope: `api`
- PKCE: `required`
- App ID slug: derived kebab-case from the friendly name
- Secrets Manager branch convention: `data/mcp/server/<name>` + `data/mcp/user/<name>`
- TF state: `state/<area>/<op>/terraform.tfstate`
- Tenant subdomain: `$CYBERARK_TENANT_SUBDOMAIN` (default `infamous`)
- Where these defaults are non-obvious or unusual, mention them in the inbox draft's `SKILL_NOTES.md`.

## What to do if you discover a new pattern

If your op revealed a useful primitive (e.g., a new auth header, a new endpoint, a TTL behavior), append a memory entry to `~/Documents/Projects/panw/memory/cyberark-tenant.md` describing it. The pattern: brief title, `**Why:**` line, `**How to apply:**` line. Keep these entries terse and link-rich with `[[wikilinks]]` to related memories.
