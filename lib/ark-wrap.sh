#!/usr/bin/env bash
# lib/ark-wrap.sh — wraps the `ark` CLI with discovery + Service User auth.
#
# Usage:
#   lib/ark-wrap.sh <service> <subgroup> <action> [flags]
#
# Example:
#   lib/ark-wrap.sh identity users list --filter type=service
#   lib/ark-wrap.sh pcloud accounts get --account-id abc123
#
# Reads CYBERARK_TENANT_SUBDOMAIN (default "infamous"). Logs in the Service User on
# every call if not already cached by `ark`. Appends mutation actions to audit/.

set -euo pipefail

_ARKW_REPO_ROOT="${IDIRA_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)}"

# shellcheck source=discovery.sh
source "${_ARKW_REPO_ROOT}/lib/discovery.sh"
# shellcheck source=auth.sh
source "${_ARKW_REPO_ROOT}/lib/auth.sh"
# shellcheck source=capture.sh
source "${_ARKW_REPO_ROOT}/lib/capture.sh"

if ! command -v ark >/dev/null 2>&1; then
  cat >&2 <<'EOF'
ark-wrap.sh: 'ark' CLI not found.

Install with:
  pipx install ark-sdk-python    # recommended
  # or
  pip install --user ark-sdk-python

Then re-run this command. Docs: https://cyberark.github.io/ark-sdk-python/latest/
EOF
  exit 127
fi

if [[ $# -lt 2 ]]; then
  echo "Usage: ark-wrap.sh <service> <subgroup> <action> [flags]" >&2
  echo "Example: ark-wrap.sh identity users list --filter type=service" >&2
  exit 2
fi

_ensure_discovered

# Make sure we're logged in (idempotent — ark caches token).
ark_service_user_login >/dev/null 2>&1 || {
  echo "ark-wrap.sh: ERROR — Service User login failed. Check auth provider and credentials." >&2
  exit 1
}

# Determine if this is a mutation (heuristic: action verb).
service="$1"; sub="$2"; action="${3:-}"
mutation=0
case "$action" in
  create|add|update|set|patch|delete|remove|destroy|disable|enable|reset|rotate|publish) mutation=1 ;;
esac

# Run.
output=$(ark exec "$@" 2>&1) && rc=0 || rc=$?
echo "$output"

# Audit if mutation succeeded.
if [[ $mutation -eq 1 && $rc -eq 0 ]]; then
  capture_audit "ark-${service}-${sub}-${action}" "ark:${service}.${sub}" "{\"args\":\"$*\"}" "applied"
fi

exit "$rc"
