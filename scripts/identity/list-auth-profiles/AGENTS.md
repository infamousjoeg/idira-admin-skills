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
