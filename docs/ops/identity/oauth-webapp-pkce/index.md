# Oauth Webapp Pkce

**Area:** `identity`  ·  **Kind:** tf/identity/oauth-webapp-pkce

# `tf/identity/oauth-webapp-pkce/` — PKCE OAuth2 web app

Creates an Idira Identity OAuth2 web application registered as a **public client** with **PKCE required** — the modern, secret-less posture appropriate for MCP servers, local CLIs, and native apps that can't safely store a `client_secret`.

Replaces the multi-call `SaasManage/ImportAppFromTemplate` + `UpdateApplicationDE` REST dance documented in `~/Documents/Projects/panw/memory/cyberark-tenant.md` (entry: *"CyberArk Identity Admin REST endpoint names — corrections"*) with a single declarative Terraform resource.

## When to use

Prompt patterns that route here:
- *"Create an OAuth webapp for a new MCP called &lt;name&gt;"*
- *"Register a public OAuth2 client with PKCE required for &lt;app&gt;"*
- *"Add an OAuth app for &lt;tool&gt; using the standard MCP development callback"*

If your client needs `client_credentials` (machine-to-machine, no human auth flow), use a Service User instead — see `tf/identity/service-user/` (forthcoming).

## What it manages

| Resource | Provider | Purpose |
|---|---|---|
| `idsec_identity_webapp.this` | `cyberark/idsec` | The OAuth2Server-template web app + its `oauth_profile` block |

## Variables

| Name | Type | Default | Required |
|---|---|---|---|
| `app_name` | `string` | — | ✅ Human-readable name in the admin UI |
| `service_name` | `string` | — | ✅ Slug used as the OAuth2 `application_id` |
| `description` | `string` | `"OAuth2 webapp for an MCP / local CLI tool, managed by idira-admin-skills."` | |
| `scopes` | `list(object)` | `[{scope="api", description="…"}]` | |
| `audience` | `string` | `mcp://<service_name>` | |
| `issuer` | `string` | _discovered_ | |
| `token_lifetime` | `string` | `"0.05:00:00"` (5h) | |
| `token_type` | `string` | `"JwtRS256"` | |
| `allow_refresh` | `bool` | `true` | |
| `allowed_auth_methods` | `list(string)` | `["AuthCodeWithPKCE"]` | |
| `must_be_oauth_client` | `bool` | `true` | |
| `default_auth_profile` | `string` | `"AlwaysAllowed"` | |
| `auth_rule_profile_id` | `string` | `null` | |
| `redirect_uri` | `string` | `"http://localhost:3000/callback"` | (informational — see Caveats) |

## Outputs

- `webapp_id` — Idira-assigned RowKey
- `service_name` — the OAuth2 `application_id`
- `token_endpoint_path` — suffix to append to `CYBERARK_IDENTITY_API_URL`
- `redirect_uri_to_set` — the intended PKCE callback (see Caveats)
- `allowed_auth_methods`, `scopes` — passthroughs

## Example

```bash
cp examples/default/terraform.tfvars.example terraform.tfvars
# edit app_name + service_name
$REPO/lib/tf-wrap.sh apply tf/identity/oauth-webapp-pkce
```

Output:

```
webapp_id           = "abc12345-…"
service_name        = "witty-muffin"
token_endpoint_path = "/Oauth2/Token/witty-muffin"
redirect_uri_to_set = "http://localhost:3000/callback"
```

## Caveats

**`redirect_uri` requires a follow-up step (v0.3.3).** The `cyberark/idsec` v0.3.3 resource schema for `idsec_identity_webapp` does *not* expose the `OpenIdConnectRedirects` field. After `terraform apply` succeeds, set the redirect URI via one of:

```bash
# Option A — ark CLI (recommended once the script wrapper lands):
$REPO/lib/ark-wrap.sh identity oauth-app update \
  --service-name "$(terraform output -raw service_name)" \
  --openid-connect-redirects "http://localhost:3000/callback"

# Option B — admin UI:
open "${CYBERARK_IDENTITY_API_URL}/admin/AppMgmt/$(terraform output -raw webapp_id)"
```

We're tracking this as a follow-up to migrate to a single `terraform apply` once the provider exposes the field.

**Default auth profile is permissive.** `AlwaysAllowed` skips MFA on app login. For production apps, set `default_auth_profile` to a stricter profile name (e.g., `"DefaultMFA"`) and pass an `auth_rule_profile_id` matching your MFA policy.

**Re-runs are idempotent.** Re-applying with the same `service_name` is a no-op (Terraform sees no drift). Changing `app_name`, `scopes`, `token_lifetime`, etc. triggers an in-place update.


## How Claude routes this

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


## Adapting for your tenant

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

