# Adapting `tf/identity/oauth-webapp-pkce/` for your tenant

If you're an AI agent (Claude Code, Cursor, Codex, etc.) helping a human apply this module on a tenant other than `infamous`, here's what to know.

## Variables the user must set

- **`app_name`** — confirm with the user. They'll see this in their admin UI.
- **`service_name`** — derive a kebab-case slug from `app_name` unless the user specifies. Validate against the `^[a-z][a-z0-9-]{1,62}[a-z0-9]$` regex.

## Variables to verify, not assume

- **`redirect_uri`** — the default `http://localhost:3000/callback` is the MCP local-dev convention. If the user mentions:
  - "production deployment" → ask for the real callback
  - "hosted MCP", "remote agent", "behind a load balancer" → ask for the real callback
  - "VS Code", "Cursor", "Claude Desktop" — those each have known callback patterns; ask the user which client.

- **`default_auth_profile`** — `AlwaysAllowed` is appropriate for dev/local clients. For production apps, ask the user about their tenant's authentication profile names (they vary per tenant) and use one that enforces MFA.

- **`auth_rule_profile_id`** — leave `null` unless the user asks to enforce per-IP-range auth profiles.

## Variables you should not change without security review

- **`allowed_auth_methods`** defaults to `["AuthCodeWithPKCE"]`. Don't add `"AuthCode"` (non-PKCE) or `"Implicit"` (deprecated) without explicit user approval.
- **`must_be_oauth_client`** defaults to `true`. Don't set to `false` without understanding the impact (allows authentication purely as the assigned Identity user without OAuth2 client_id verification).
- **`token_lifetime`** defaults to 5 hours. Reasonable upper bound. Don't extend beyond 24 hours without security review.

## Things tenant-specific to `infamous` baked in

None. This module is fully parameterized — the only tenant assumption is the provider's `ARK_USERNAME` / `ARK_SECRET` env vars, which are populated by `lib/auth.sh` from whatever secret store the user configured (see root `AGENTS.md`).

## Things NOT YET handled by this module (known follow-ups)

- **Redirect URI** — the v0.3.3 schema doesn't expose `OpenIdConnectRedirects`. After `terraform apply`, you must run `ark exec identity oauth-app update --service-name <name> --openid-connect-redirects <uri>` (or visit the admin UI). The `redirect_uri_to_set` output reminds the user.
- **User/role permissions** — this module creates the app but does NOT assign users or roles to it. Use `idsec_identity_webapp_permission` (a separate resource) or `tf/identity/oauth-webapp-permission/` (forthcoming) once we capture that pattern.
- **`UpdateApplicationDE` TPDict fields** — fields like `Confidential`, `RequirePKCE`, `ServiceName` that the legacy REST flow set via `UpdateApplicationDE` are inferred by the provider from `allowed_auth = ["AuthCodeWithPKCE"]` + `must_be_oauth_client = true`. If your tenant has a non-default Identity build, you may need to verify these settings via the admin UI after apply.

## How to verify after apply

1. `terraform output webapp_id` — confirm the resource was created.
2. Hit `${CYBERARK_IDENTITY_API_URL}/admin/AppMgmt/<webapp_id>` in a browser; verify "OAuth2 Server" type, PKCE required, scope `api` present.
3. Mint a test token (after you've set the redirect URI):
   ```bash
   # Using ark:
   ark exec identity oauth-app test-token --service-name <service_name>
   ```
4. Sanity-check audit: `/ca-audit --op identity-oauth-webapp-pkce` should show the apply with your params.

## When to update this AGENTS.md

If you (the AI agent) discover that a specific tenant requires a different `template_name`, a different `default_auth_profile`, or a setting we haven't surfaced as a variable — propose a PR to this file documenting it, and (if it generalizes) add a new variable.
