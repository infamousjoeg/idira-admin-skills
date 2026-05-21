---
name: oauth-webapp-pkce
description: Use when the user wants to create an OAuth2 web application on their Idira (CyberArk Identity Security Platform) tenant with PKCE required — the standard public-client pattern for MCP servers, local CLIs, and native apps that cannot safely store a client_secret. Routes to the tf/identity/oauth-webapp-pkce/ Terraform module via lib/tf-wrap.sh.
---

# oauth-webapp-pkce — Create a PKCE OAuth2 web app

Use this skill when the user wants to register an OAuth2 web app on their Idira tenant for a client that uses the authorization-code flow with PKCE. Typical triggers:

- "Create an OAuth webapp for a new MCP called &lt;name&gt;"
- "Register a public OAuth2 client with PKCE required for &lt;app&gt;"
- "Add an OAuth app for &lt;tool&gt; using the standard MCP development callback"
- "Set up an OAuth web app for &lt;X&gt;" (when X is clearly a public client, not a server-side confidential client)

**Don't use this skill for:**
- Service Users (machine-to-machine auth) — use `tf/identity/service-user/` (forthcoming).
- Confidential OAuth2 clients that need a `client_secret` (rare; usually a security smell).
- Updating an existing webapp — that needs a different module or `ark exec identity oauth-app update`.

## How to invoke

1. Read the user's intent. Extract or derive:
   - `app_name` — human-readable, what they'd see in the admin UI. If they just say "for MCP called witty-muffin", use `"MCP — Witty Muffin"`.
   - `service_name` — kebab-case slug derived from `app_name` (e.g., `witty-muffin`). Validate against `^[a-z][a-z0-9-]{1,62}[a-z0-9]$`.

2. Apply Joe's defaults from `CLAUDE.md` for everything else:
   - `redirect_uri`: `http://localhost:3000/callback` (unless user mentions hosted/remote/production)
   - `scopes`: `[{scope="api", description="..."}]`
   - `allowed_auth_methods`: `["AuthCodeWithPKCE"]`
   - `token_lifetime`: `"0.05:00:00"`
   - `default_auth_profile`: `"AlwaysAllowed"`

3. Write a `terraform.tfvars` (use `cp examples/default/terraform.tfvars.example terraform.tfvars` as the seed; edit `app_name` + `service_name`).

4. Run `lib/tf-wrap.sh apply tf/identity/oauth-webapp-pkce` — the wrapper handles `init`, `plan`, confirmation prompt, `apply`, and audit logging.

5. After apply: print the outputs (`webapp_id`, `service_name`, `token_endpoint_path`). Then surface the follow-up redirect-URI step from the README's Caveats section.

## Idempotency

Re-running with the same `service_name` is a no-op. Changing `app_name`, `scopes`, `token_lifetime`, etc. triggers an in-place update.

## If the user wants something this doesn't cover

- **A different callback URL** — set `redirect_uri` (informational) and follow up with `ark exec` per the README.
- **MFA on app login** — set `default_auth_profile` to a tenant-specific MFA profile name.
- **`client_credentials` grant too** — extend `allowed_auth_methods` to `["AuthCodeWithPKCE", "ClientCreds"]`. Note that adds a machine-to-machine path; confirm intent.

When in doubt about a setting, ASK the user — but don't ask about things this skill's defaults already cover (callback, scope, PKCE, token lifetime).
