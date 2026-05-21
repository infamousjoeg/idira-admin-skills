---
name: identity-list-auth-profiles
description: Use when the user asks about their Idira tenant's authentication profile names or UUIDs — the named MFA/auth policies ("DefaultMFA", "AlwaysAllowed", "Admin2FA", etc.) that other modules reference as their default_auth_profile. Read-only. Should also be invoked proactively before any op that needs an authentication profile parameter, so you don't guess at profile names.
---

# identity-list-auth-profiles — List Idira authentication profiles

Use this skill when:
- The user explicitly asks "what auth profiles do I have", "list MFA policies", "what's the UUID of <profile name>", etc.
- You are about to invoke another op (like `oauth-webapp-pkce` or anything in `tf/identity/`) that asks for an authentication profile name or UUID, and you don't have a current map of the tenant's profiles. **Run this first** rather than guessing or hardcoding `AlwaysAllowed`.

**Don't use this skill for:**
- Creating, updating, or deleting profiles — `ark exec identity policies` has `add-authentication-profile` etc. for that.

## How to invoke

```bash
$REPO/scripts/identity/list-auth-profiles/run.sh
# or, filtered:
$REPO/scripts/identity/list-auth-profiles/run.sh --filter MFA --names-only
```

The script handles discovery + Service User auth automatically.

## After running

Cache the result in your current conversation context. When asked for an auth profile elsewhere, use the discovered names/UUIDs directly. If the user mentions a profile name that doesn't appear in the list, surface that as a likely typo or "the profile doesn't exist on this tenant" before proceeding.

## Idempotency

Trivially read-only. Safe to run as many times as needed.
