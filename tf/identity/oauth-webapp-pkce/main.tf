################################################################################
# tf/identity/oauth-webapp-pkce — Idira OAuth2 web app with PKCE required
#
# Creates an OAuth2Server-template web application on the Idira tenant, configured
# for public PKCE clients (MCPs, local CLIs, native apps) with the strict
# no-client-secret posture documented in ~/Documents/Projects/panw/memory/cyberark-tenant.md.
#
# Provider auth: `cyberark/idsec` reads credentials from these env vars (set by
# lib/auth.sh + lib/discovery.sh — see lib/tf-wrap.sh):
#   IDSEC_SERVICE_USER         = Identity Service User login
#   IDSEC_SERVICE_TOKEN        = Identity Service User secret
#   IDSEC_SUBDOMAIN            = tenant subdomain (e.g., "infamous")
#   IDSEC_SERVICE_AUTHORIZED_APP = OAuth2 app slug (default __idaptive_cybr_user_oidc)
# Never commit these values; never set them in tfvars.
################################################################################

provider "idsec" {
  auth_method = "identity_service_user"
  # Other config (subdomain, service_user, service_token, service_authorized_app)
  # comes from IDSEC_* env vars — see header comment.
}

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
