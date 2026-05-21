# oauth-webapp-pkce — Promotion Notes

## What this does

Creates an Idira Identity OAuth2 web app registered as a public client with PKCE required. The successor to the multi-call `SaasManage/ImportAppFromTemplate` + `UpdateApplicationDE` REST dance.

## Defaults applied without asking

- Callback URL: `http://localhost:3000/callback` (standard MCP dev pattern)
- Scope: `api`
- PKCE: required (`allowed_auth = ["AuthCodeWithPKCE"]`)
- Token lifetime: 5 hours (`0.05:00:00`)
- Refresh tokens: enabled
- Token type: `JwtRS256`
- Default auth profile: `AlwaysAllowed` (no MFA on app login — appropriate for dev MCPs)
- App ID slug: kebab-case-lowercased derivation from `app_name`
- Audience: `mcp://<service_name>` convention

## What worked / what didn't

**Worked:** The `OAuth2Server` template name from the provider example. The `oauth_profile` nested block with `allowed_auth = ["AuthCodeWithPKCE"]` (per memory entry "CyberArk Identity Admin REST endpoint names — corrections").

**Didn't (yet):** The v0.3.3 schema does NOT expose `OpenIdConnectRedirects` (`redirect_uri`). This must be set via `ark exec identity oauth-app update` or the admin UI after `terraform apply`. The module emits a `redirect_uri_to_set` output as a reminder and the `AGENTS.md` flags this. Track upstream provider issue.

## Suggested catalog placement

`tf/identity/oauth-webapp-pkce/` (already here).

## Suggested SKILL.md description

Use when a user wants an OAuth2 web application registered on their Idira tenant with PKCE required — the standard pattern for MCP servers, local CLIs, and native apps that cannot safely store a `client_secret`. Routes to this Terraform module via `lib/tf-wrap.sh apply`. Sets sensible defaults for callback URL (`http://localhost:3000/callback`), scope (`api`), and token lifetime (5h); allows override via variables. Emits the new `webapp_id`, the OAuth2 `service_name`, and the token endpoint suffix. Caveat: the redirect URI must be configured as a follow-up via `ark` CLI or the admin UI until the provider exposes the field.
