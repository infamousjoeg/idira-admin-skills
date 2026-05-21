# list-auth-profiles — Promotion Notes

## What this does

Thin wrapper around `ark exec identity policies list-authentication-profiles` with discovery + auth helpers, optional name filtering, and a names-only projection.

## Defaults applied without asking

- Output format: full JSON (most useful for piping into `jq` for downstream automation)
- Filter: none (returns all profiles)

## What worked / what didn't

**Worked:** The `ark exec identity policies list-authentication-profiles` command (raw JSON, no args required). Service User auth via `ark login --silent --type=identity_service_user`.

**Note for the catalog:** The original plan called for `list-service-users` but that subcommand doesn't exist in `ark` v2.0+ (`ark exec identity users` only has `create-user`, `update-user`, `delete-user`, `user-by-name`, `user-id-by-name`, `reset-user-password`). Switched to `list-authentication-profiles` which is also a useful read-only example AND fills a concrete need (discovering profile names referenced by other modules).

## Suggested catalog placement

`scripts/identity/list-auth-profiles/` (already here).

## Suggested SKILL.md description

Use when a user asks about their tenant's authentication profile names or UUIDs — the named MFA/auth policies (like "DefaultMFA", "AlwaysAllowed") that other ops reference as their `default_auth_profile`. Read-only, safe to invoke anytime. Returns JSON or a names-only projection with optional substring filtering. Should be invoked proactively before any module that asks for an auth profile, so the AI agent doesn't guess.
