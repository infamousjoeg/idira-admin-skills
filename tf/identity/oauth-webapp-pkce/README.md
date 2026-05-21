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

## Prerequisite — Service User must have webapp-management rights

The Identity Service User used by the provider needs **either** of:
- Membership in the **"System Administrator"** role, OR
- Explicit **"Application Management"** rights on the tenant

Without one of these, `terraform apply` against this module returns the Idira error `_I18N_System.UnauthorizedAccessException` ("You are not authorized to perform this operation"). The plan succeeds; only the create call fails. To grant:

1. Open the Idira admin UI at `${CYBERARK_IDENTITY_API_URL}/admin/` (resolved by `lib/discovery.sh`).
2. Navigate to **Core Services → Users**, find your Service User, click into it.
3. Either add it to the **System Administrator** role (broad) or grant **Application Management** under the user's permissions tab (narrower, recommended for least-privilege).
4. Re-run `terraform apply`.

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
