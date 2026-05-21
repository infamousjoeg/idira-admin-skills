#!/usr/bin/env bash
# lib/discovery.sh — resolve per-tenant URLs from CyberArk Platform Discovery.
#
# Usage:
#   source lib/discovery.sh
#   discover "$CYBERARK_TENANT_SUBDOMAIN"     # or whatever subdomain
#
# Exports CYBERARK_*_API_URL env vars consumed by auth.sh, tf-wrap.sh, ark-wrap.sh.
# Caches the discovery response at cache/discovery-<subdomain>.json (gitignored).

set -uo pipefail

# Directory where this script lives — works whether sourced from repo root or elsewhere.
_DISCOVERY_REPO_ROOT="${IDIRA_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)}"
_DISCOVERY_CACHE_DIR="${_DISCOVERY_REPO_ROOT}/cache"
_DISCOVERY_TTL_SECONDS="${DISCOVERY_TTL_SECONDS:-86400}"  # 1 day default

discover() {
  local sub="${1:-${CYBERARK_TENANT_SUBDOMAIN:-}}"

  if [[ -z "$sub" ]]; then
    echo "discovery.sh: ERROR — no subdomain provided. Set CYBERARK_TENANT_SUBDOMAIN or pass as arg." >&2
    return 1
  fi

  mkdir -p "$_DISCOVERY_CACHE_DIR"
  local cache="${_DISCOVERY_CACHE_DIR}/discovery-${sub}.json"

  if [[ ! -f "$cache" ]] || _discovery_cache_stale "$cache"; then
    local url="https://platform-discovery.cyberark.cloud/api/v2/services/subdomain/${sub}"
    echo "discovery.sh: fetching ${url}" >&2
    if ! curl -fsSL "$url" -o "${cache}.tmp"; then
      echo "discovery.sh: ERROR — failed to fetch ${url}" >&2
      rm -f "${cache}.tmp"
      return 1
    fi
    mv "${cache}.tmp" "$cache"
  fi

  # Export each service's API URL. Be tolerant of missing services (.api may be null).
  export CYBERARK_TENANT_SUBDOMAIN="$sub"
  export CYBERARK_DISCOVERY_CACHE="$cache"
  export CYBERARK_IDENTITY_API_URL=$(_discovery_get "$cache" '.identity_administration.api')
  export CYBERARK_IDENTITY_USER_PORTAL_URL=$(_discovery_get "$cache" '.identity_user_portal.api')
  export CYBERARK_SECRETS_MANAGER_API_URL=$(_discovery_get "$cache" '.secrets_manager.api')
  export CYBERARK_SECRETS_HUB_API_URL=$(_discovery_get "$cache" '.secrets_hub.api')
  export CYBERARK_PCLOUD_API_URL=$(_discovery_get "$cache" '.pcloud.api')
  export CYBERARK_SIA_API_URL=$(_discovery_get "$cache" '.jit.api')        # SIA = JIT/DPA service name
  export CYBERARK_SCA_API_URL=$(_discovery_get "$cache" '.sca.api')
  export CYBERARK_CMGR_API_URL=$(_discovery_get "$cache" '.component_manager.api')
  export CYBERARK_ITDR_API_URL=$(_discovery_get "$cache" '.itdr.api')
  export CYBERARK_UAP_API_URL=$(_discovery_get "$cache" '.uap.api')
  export CYBERARK_RECORDING_API_URL=$(_discovery_get "$cache" '.recording.api')
  export CYBERARK_SESSION_MONITORING_API_URL=$(_discovery_get "$cache" '.session_monitoring.api')
  export CYBERARK_AUDIT_API_URL=$(_discovery_get "$cache" '.audit.api')
  export CYBERARK_ANALYTICS_API_URL=$(_discovery_get "$cache" '.analytics.api')
  export CYBERARK_DMS_API_URL=$(_discovery_get "$cache" '.dms.api')

  return 0
}

_discovery_cache_stale() {
  local cache="$1"
  local now
  local mtime
  local age
  now=$(date +%s)
  if stat --version 2>/dev/null | grep -q GNU; then
    mtime=$(stat -c %Y "$cache")           # GNU stat
  else
    mtime=$(stat -f %m "$cache")            # BSD/macOS stat
  fi
  age=$((now - mtime))
  [[ $age -gt $_DISCOVERY_TTL_SECONDS ]]
}

_discovery_get() {
  local cache="$1"
  # NOTE: do NOT name this var `path` — that's a zsh-reserved array (the
  # tied counterpart of $PATH). Shadowing it inside a function breaks
  # external-command resolution (jq, curl, etc.) for the function body.
  local jq_path="$2"
  local val
  val=$(jq -r "${jq_path} // empty" "$cache" 2>/dev/null)
  [[ -n "$val" ]] && echo "$val"
}

# Convenience function for ad-hoc CLI use:
discover_show() {
  local sub="${1:-${CYBERARK_TENANT_SUBDOMAIN:-}}"
  discover "$sub" || return 1
  env | grep '^CYBERARK_' | sort
}

# If invoked directly (not sourced), run discover_show. We detect "sourced" with
# `(return 0 2>/dev/null)` — only valid in a sourced context, so it returns 0
# when sourced and non-zero when executed.
if ! (return 0 2>/dev/null); then
  discover_show "$@"
fi
