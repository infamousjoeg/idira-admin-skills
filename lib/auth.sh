#!/usr/bin/env bash
# lib/auth.sh — mint Idira Identity Service User bearer tokens for API calls.
#
# Default secret-store: Conceal (macOS Keychain via Summon). Paths:
#   - infamousdev/claudecode/client_id     (Service User login)
#   - infamousdev/claudecode/client_secret (Service User password)
#
# Override by setting CYBERARK_AUTH_PROVIDER to one of:
#   - conceal (default — Joe's setup)
#   - env     (CYBERARK_SERVICE_USER + CYBERARK_SERVICE_USER_SECRET env vars)
#   - 1password (op://...; see _auth_get_1password)
#   - vault    (HashiCorp Vault; see _auth_get_vault)
#   - aws-secrets-manager  (see _auth_get_aws_sm)
#
# For other secret stores, implement _auth_get_<provider> and add to the case.

set -uo pipefail

_AUTH_REPO_ROOT="${IDIRA_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)}"

# Source discovery so we have CYBERARK_IDENTITY_API_URL available.
# shellcheck source=discovery.sh
source "${_AUTH_REPO_ROOT}/lib/discovery.sh"

# ─── Public functions ───────────────────────────────────────────────────────

# mint-identity-token: prints a bearer token to stdout. Token TTL: 1 hour (default Identity OAuth2).
mint_identity_token() {
  _ensure_discovered || return 1

  local app_id="${CYBERARK_IDENTITY_OAUTH_APP:-cyberark_apis}"
  local endpoint="${CYBERARK_IDENTITY_API_URL}/Oauth2/Token/${app_id}"

  # Get creds into env vars in-process; never write to disk.
  _auth_load_credentials || return 1

  local response
  response=$(curl -fsS -X POST "$endpoint" \
    -u "${CYBERARK_SERVICE_USER}:${CYBERARK_SERVICE_USER_SECRET}" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=client_credentials' \
    --data-urlencode 'scope=api')

  if [[ -z "$response" ]]; then
    echo "auth.sh: ERROR — token endpoint returned empty body" >&2
    return 1
  fi

  jq -re '.access_token' <<<"$response" || {
    echo "auth.sh: ERROR — no access_token in response: $response" >&2
    return 1
  }
}

# ark_service_user_login: configures and logs in `ark` CLI as the Service User. Idempotent.
ark_service_user_login() {
  _ensure_discovered || return 1
  if ! command -v ark >/dev/null 2>&1; then
    echo "auth.sh: 'ark' CLI not found. Install with: pipx install ark-sdk-python" >&2
    return 127
  fi
  _auth_load_credentials || return 1
  # Use ark's built-in service-user auth.
  ARK_USERNAME="$CYBERARK_SERVICE_USER" \
  ARK_SECRET="$CYBERARK_SERVICE_USER_SECRET" \
    ark login --silent --type=identity_service_user
}

# ─── Internal ───────────────────────────────────────────────────────────────

_ensure_discovered() {
  if [[ -z "${CYBERARK_IDENTITY_API_URL:-}" ]]; then
    discover "${CYBERARK_TENANT_SUBDOMAIN:-infamous}" || return 1
  fi
}

_auth_load_credentials() {
  # Already loaded? Skip.
  if [[ -n "${CYBERARK_SERVICE_USER:-}" && -n "${CYBERARK_SERVICE_USER_SECRET:-}" ]]; then
    return 0
  fi

  local provider="${CYBERARK_AUTH_PROVIDER:-conceal}"

  case "$provider" in
    conceal)     _auth_get_conceal ;;
    env)         _auth_get_env ;;
    1password)   _auth_get_1password ;;
    vault)       _auth_get_vault ;;
    aws-secrets-manager) _auth_get_aws_sm ;;
    *)
      echo "auth.sh: unknown CYBERARK_AUTH_PROVIDER '$provider'" >&2
      return 1
      ;;
  esac
}

# Joe's default: Summon+Conceal pulls creds from macOS Keychain. We spawn a subshell that
# inherits SUMMON_PROVIDER_PATH'd values without ever touching disk.
_auth_get_conceal() {
  if ! command -v summon >/dev/null 2>&1 || ! command -v conceal >/dev/null 2>&1; then
    echo "auth.sh: summon and/or conceal not on PATH. See https://cyberark.github.io/summon/ + https://github.com/cyberark/conceal" >&2
    return 127
  fi

  local id_path="${CYBERARK_CONCEAL_CLIENT_ID_PATH:-infamousdev/claudecode/client_id}"
  local secret_path="${CYBERARK_CONCEAL_CLIENT_SECRET_PATH:-infamousdev/claudecode/client_secret}"

  # Use summon to inject values as env vars into THIS shell via process substitution.
  # The trick: summon prints `export FOO=...` lines we eval; we trap to clear afterward.
  local out
  out=$(summon -p conceal --yaml "
CYBERARK_SERVICE_USER: !var ${id_path}
CYBERARK_SERVICE_USER_SECRET: !var ${secret_path}
" -- /usr/bin/env | grep -E '^CYBERARK_SERVICE_USER' || true)

  if [[ -z "$out" ]]; then
    echo "auth.sh: ERROR — failed to load Conceal-stored creds at ${id_path} / ${secret_path}" >&2
    return 1
  fi

  while IFS= read -r line; do
    export "$line"
  done <<<"$out"
}

_auth_get_env() {
  : "${CYBERARK_SERVICE_USER:?auth.sh: CYBERARK_SERVICE_USER not set}"
  : "${CYBERARK_SERVICE_USER_SECRET:?auth.sh: CYBERARK_SERVICE_USER_SECRET not set}"
}

_auth_get_1password() {
  if ! command -v op >/dev/null 2>&1; then
    echo "auth.sh: 1Password CLI 'op' not on PATH. See https://developer.1password.com/docs/cli/" >&2
    return 127
  fi
  : "${CYBERARK_1PASSWORD_CLIENT_ID_REF:?auth.sh: CYBERARK_1PASSWORD_CLIENT_ID_REF not set (e.g. 'op://Personal/Idira Service User/client_id')}"
  : "${CYBERARK_1PASSWORD_CLIENT_SECRET_REF:?auth.sh: CYBERARK_1PASSWORD_CLIENT_SECRET_REF not set}"
  export CYBERARK_SERVICE_USER=$(op read "$CYBERARK_1PASSWORD_CLIENT_ID_REF")
  export CYBERARK_SERVICE_USER_SECRET=$(op read "$CYBERARK_1PASSWORD_CLIENT_SECRET_REF")
}

_auth_get_vault() {
  if ! command -v vault >/dev/null 2>&1; then
    echo "auth.sh: HashiCorp Vault CLI 'vault' not on PATH." >&2
    return 127
  fi
  : "${CYBERARK_VAULT_PATH:?auth.sh: CYBERARK_VAULT_PATH not set (e.g. 'secret/idira/service-user')}"
  local kv
  kv=$(vault kv get -format=json "$CYBERARK_VAULT_PATH")
  export CYBERARK_SERVICE_USER=$(jq -r '.data.data.client_id' <<<"$kv")
  export CYBERARK_SERVICE_USER_SECRET=$(jq -r '.data.data.client_secret' <<<"$kv")
}

_auth_get_aws_sm() {
  if ! command -v aws >/dev/null 2>&1; then
    echo "auth.sh: AWS CLI not on PATH." >&2
    return 127
  fi
  : "${CYBERARK_AWS_SECRET_ID:?auth.sh: CYBERARK_AWS_SECRET_ID not set (e.g. 'arn:aws:secretsmanager:us-east-1:123:secret:idira-service-user')}"
  local secret
  secret=$(aws secretsmanager get-secret-value --secret-id "$CYBERARK_AWS_SECRET_ID" --query SecretString --output text)
  export CYBERARK_SERVICE_USER=$(jq -r '.client_id' <<<"$secret")
  export CYBERARK_SERVICE_USER_SECRET=$(jq -r '.client_secret' <<<"$secret")
}

# If invoked directly with a subcommand, dispatch.
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
  case "${1:-}" in
    mint-identity-token) mint_identity_token ;;
    ark-login)           ark_service_user_login ;;
    *)
      echo "Usage: auth.sh {mint-identity-token | ark-login}" >&2
      exit 2
      ;;
  esac
fi
