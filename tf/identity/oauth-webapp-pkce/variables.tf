variable "app_name" {
  description = "Human-readable name of the OAuth2 web app as it appears in the Identity admin UI (e.g., \"MCP — Witty Muffin\")."
  type        = string

  validation {
    condition     = length(var.app_name) > 0 && length(var.app_name) <= 80
    error_message = "app_name must be between 1 and 80 characters."
  }
}

variable "service_name" {
  description = "Short slug used as the OAuth2 application ID (the `<app_id>` in `$${CYBERARK_IDENTITY_API_URL}/Oauth2/Token/<app_id>` and the `OAUTH_APPLICATION_ID` in client configs). Kebab-case, lowercased, no spaces."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,62}[a-z0-9]$", var.service_name))
    error_message = "service_name must be 3-64 chars, kebab-case, start with a letter and end with a letter or digit."
  }
}

variable "description" {
  description = "Optional human-readable description shown in the admin UI."
  type        = string
  default     = "OAuth2 webapp for an MCP / local CLI tool, managed by idira-admin-skills."
}

variable "scopes" {
  description = "OAuth2 scopes the app exposes. Defaults to the single `api` scope used by Service-User-style admin clients and the `ark` CLI."
  type = list(object({
    scope       = string
    description = optional(string)
  }))
  default = [
    { scope = "api", description = "Full Identity Security Platform API access" }
  ]
}

variable "audience" {
  description = "OAuth2 audience claim baked into issued tokens. Convention: `mcp://<service_name>` for MCP servers; override for non-MCP clients."
  type        = string
  default     = null
}

variable "issuer" {
  description = "OAuth2 issuer URL. Defaults to the discovered Identity tenant URL (e.g., `https://ack4386.id.cyberark.cloud`). When null, the provider derives it from the authenticated tenant."
  type        = string
  default     = null
}

variable "token_lifetime" {
  description = "Access token lifetime in the Idira `D.HH:MM:SS` format (e.g., `0.05:00:00` = 5 hours)."
  type        = string
  default     = "0.05:00:00"
}

variable "token_type" {
  description = "OAuth2 token signature algorithm. Options seen in the wild: `JwtRS256`, `JwtHS256`. PKCE-required public clients almost always want `JwtRS256`."
  type        = string
  default     = "JwtRS256"

  validation {
    condition     = contains(["JwtRS256", "JwtHS256"], var.token_type)
    error_message = "token_type must be one of: JwtRS256, JwtHS256."
  }
}

variable "allow_refresh" {
  description = "Whether the app issues refresh tokens. Recommended `true` for long-running MCP/CLI clients so users aren't forced through PKCE on every short-lived access-token expiry."
  type        = bool
  default     = true
}

variable "allowed_auth_methods" {
  description = <<-EOT
    OAuth2 grant types the app accepts. Values accepted by `cyberark/idsec` v0.3.3:
      - `AuthorizationCode` — authorization-code flow (use for PKCE public clients; see note below)
      - `ClientCreds`       — client_credentials (machine-to-machine, requires Service User)
      - `Implicit`          — implicit grant (deprecated, do not enable)
      - `ResourceCreds`     — ROPC / Resource Owner Password Credentials (do not enable)

    **Important:** the v0.3.3 schema does NOT yet expose an explicit `require_pkce` /
    `RequirePKCE` attribute. Setting `allowed_auth = ["AuthorizationCode"]` permits the
    auth-code flow but does NOT by itself enforce PKCE. After `terraform apply`, the
    module emits a `pkce_to_enforce` output reminding you to set `RequirePKCE: true` on
    the app via `ark exec identity oauth-app update` (or the admin UI) until the
    provider exposes the field. See module README.
  EOT
  type        = list(string)
  default     = ["AuthorizationCode"]

  validation {
    condition     = length(var.allowed_auth_methods) > 0
    error_message = "At least one auth method must be allowed."
  }

  validation {
    condition     = alltrue([for m in var.allowed_auth_methods : contains(["AuthorizationCode", "ClientCreds", "Implicit", "ResourceCreds"], m)])
    error_message = "allowed_auth_methods values must be one of: AuthorizationCode, ClientCreds, Implicit, ResourceCreds."
  }
}

variable "must_be_oauth_client" {
  description = "Whether the calling client must present an OAuth2 client_id (vs. authenticating purely as the assigned Identity user). For PKCE webapps used by MCPs/CLIs: `true`."
  type        = bool
  default     = true
}

variable "default_auth_profile" {
  description = "Identity authentication profile applied to users hitting this app. `AlwaysAllowed` is the no-MFA default present on every Idira tenant; tighten for production apps."
  type        = string
  default     = "AlwaysAllowed"
}

variable "auth_rule_profile_id" {
  description = "Authentication profile UUID applied by the in-corp-IP auth rule. When null, the rule still fires but no extra profile is applied. Set to a stricter profile (e.g., MFA-required) for prod tenants."
  type        = string
  default     = null
}

variable "redirect_uri" {
  description = <<-EOT
    PKCE callback URL. **Currently informational only** — the documented v0.3.3 schema for `idsec_identity_webapp` does not expose a `redirect_uri` (a.k.a. `OpenIdConnectRedirects`) field. After `terraform apply`, this module emits a `redirect_uri_to_set` output reminding you to PATCH the app's `OpenIdConnectRedirects` field via `ark exec identity oauth-app update` (or the admin UI) until the provider catches up. Default suits standard local-MCP development.
  EOT
  type        = string
  default     = "http://localhost:3000/callback"
}
