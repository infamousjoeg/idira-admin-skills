output "webapp_id" {
  description = "Idira-assigned RowKey for the OAuth2 web app. Used as the resource ID for imports and as the `webapp_id` in admin REST calls."
  value       = idsec_identity_webapp.this.webapp_id
}

output "service_name" {
  description = "The OAuth2 application slug — this is what your client sets as `OAUTH_APPLICATION_ID` (or equivalent) in its config."
  value       = idsec_identity_webapp.this.service_name
}

output "token_endpoint_path" {
  description = "Suffix to append to `$${CYBERARK_IDENTITY_API_URL}` to obtain the OAuth2 token mint endpoint for this app. Full URL example: `https://ack4386.id.cyberark.cloud/Oauth2/Token/<service_name>`."
  value       = "/Oauth2/Token/${idsec_identity_webapp.this.service_name}"
}

output "redirect_uri_to_set" {
  description = "Reminder: the PKCE redirect URI is not yet exposed by the cyberark/idsec v0.3.3 schema. After apply, set it via `ark exec identity oauth-app update --service-name <service_name> --openid-connect-redirects <uri>` or the admin UI. See the module README for the full procedure."
  value       = var.redirect_uri
}

output "allowed_auth_methods" {
  description = "OAuth2 grant types enabled on the app. PKCE-only by default."
  value       = var.allowed_auth_methods
}

output "scopes" {
  description = "OAuth2 scopes the app exposes."
  value       = [for s in var.scopes : s.scope]
}
