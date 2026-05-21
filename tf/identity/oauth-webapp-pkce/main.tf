################################################################################
# tf/identity/oauth-webapp-pkce — Idira OAuth2 web app with PKCE required
#
# Creates an OAuth2Server-template web application on the Idira tenant, configured
# for public PKCE clients (MCPs, local CLIs, native apps) with the strict
# no-client-secret posture documented in ~/Documents/Projects/panw/memory/cyberark-tenant.md.
#
# Provider auth: `cyberark/idsec` resolves its tenant URL + credentials from
# ARK_USERNAME / ARK_SECRET env vars (Service User), populated by lib/auth.sh
# in this repo. Don't set them inline.
################################################################################

resource "idsec_identity_webapp" "this" {
  template_name        = "OAuth2Server"
  webapp_name          = var.app_name
  service_name         = var.service_name
  description          = var.description
  webapp_login_type    = "AuthenticationRule"
  default_auth_profile = var.default_auth_profile

  auth_rules = {
    enabled    = true
    type       = "RowSet"
    unique_key = "Condition"
    value = var.auth_rule_profile_id == null ? [] : [
      {
        conditions = [
          {
            op   = "OpInCorpIpRange"
            prop = "IpAddress"
          }
        ]
        profile_id = var.auth_rule_profile_id
      }
    ]
  }

  oauth_profile = {
    allowed_auth          = var.allowed_auth_methods
    audience              = coalesce(var.audience, "mcp://${var.service_name}")
    issuer                = var.issuer
    must_be_oauth_client  = var.must_be_oauth_client
    allow_refresh         = var.allow_refresh
    token_type            = var.token_type
    token_lifetime_string = var.token_lifetime

    known_scopes = [
      for s in var.scopes : {
        scope       = s.scope
        description = coalesce(s.description, s.scope)
      }
    ]
  }
}
