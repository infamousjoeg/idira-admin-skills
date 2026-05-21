# List Auth Profiles

**Area:** `identity`  ·  **Kind:** scripts//identity/list-auth-profiles

# `scripts/identity/list-auth-profiles/` — list Idira authentication profiles

Lists every authentication profile configured on the tenant — the tenant-specific named profiles ("DefaultMFA", "AlwaysAllowed", "Admin2FA", etc.) that govern user login flows and that other captured ops (like `tf/identity/oauth-webapp-pkce/`'s `default_auth_profile` variable) reference.

Read-only. Safe to run anytime. No state changes.

## When to use

- *"What authentication profiles exist on my tenant?"*
- *"Show me the MFA policies I can attach to an OAuth app."*
- *"What's the UUID of the `DefaultMFA` profile?"*

## Usage

```bash
scripts/identity/list-auth-profiles/run.sh
scripts/identity/list-auth-profiles/run.sh --names-only
scripts/identity/list-auth-profiles/run.sh --filter MFA
scripts/identity/list-auth-profiles/run.sh --filter MFA --names-only
```

## Output

Default: full JSON array of profile objects with all fields (`Uuid`, `Name`, `Description`, `AuthFactors`, etc.).

`--names-only` flattens to `<uuid>  <name>` per line. Pipe-friendly:

```bash
scripts/identity/list-auth-profiles/run.sh --names-only | grep -i mfa
# 3a4b5c6d-...  DefaultMFA
# 9d8c7b6a-...  Admin2FA
```

## How it works

1. Sources `lib/discovery.sh` to resolve the tenant Identity URL.
2. Sources `lib/auth.sh` to log in the configured Identity Service User via `ark login`.
3. Calls `ark exec identity policies list-authentication-profiles` (raw JSON output).
4. Optionally filters by name substring (case-insensitive) and projects to UUID+name.

## Requirements

- `ark` CLI: `pipx install ark-sdk-python`
- `jq`: `brew install jq`
- Configured Service User credentials per the [Get started](https://infamousjoeg.github.io/idira-admin-skills/getting-started/) guide.


## Adapting for your tenant

# Adapting `scripts/identity/list-auth-profiles/` for your tenant

This op is fully tenant-portable as-is — no tenant-specific values are hardcoded. You only need:

- `CYBERARK_TENANT_SUBDOMAIN` set (the script discovers everything else)
- Valid Identity Service User credentials (configured via `CYBERARK_AUTH_PROVIDER` per the root `AGENTS.md`)
- `ark` CLI installed
- `jq` installed

## What the output looks like

Each authentication profile object includes:
- `Uuid` — the ID you'd use in TF modules (e.g., as `auth_rule_profile_id`)
- `Name` — the human-readable profile name
- `Description`, `AuthFactors`, `PassThroughDuration`, etc.

Profile names are tenant-specific. Common patterns:
- `AlwaysAllowed` (default, present on every tenant — no MFA)
- `DefaultMFA` or `DefaultOtherLogin Profile`
- Custom names per tenant (e.g., `Admin2FA`, `Production-Strict`, `Contractor-MFA`)

## When the AI agent should run this proactively

When a downstream op asks for a `default_auth_profile`, `auth_rule_profile_id`, or any "which authentication profile?" parameter, run this script first to discover the tenant's profile names. Don't guess; don't hardcode `AlwaysAllowed` without confirming it exists.

## Notes for non-Conceal secret stores

The script delegates auth to `lib/auth.sh`, which respects `CYBERARK_AUTH_PROVIDER`. No changes here are needed if you swap from Conceal to 1Password / Vault / AWS Secrets Manager — configure your secret store as documented in the root `AGENTS.md` and re-run.

