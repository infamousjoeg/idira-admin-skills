#!/usr/bin/env bash
# RISK: read
# DESCRIPTION: List every authentication profile configured on the Idira tenant.
#              Useful for discovering tenant-specific profile names (e.g., "DefaultMFA",
#              "AlwaysAllowed", "Admin2FA") to use as `default_auth_profile` in TF modules.
#
# Provider: ark CLI (cyberark/ark-sdk-python)
# Outputs: JSON list of profiles. Filter with --filter <substring>.
#
# Usage:
#   scripts/identity/list-auth-profiles/run.sh                    # all profiles, full JSON
#   scripts/identity/list-auth-profiles/run.sh --names-only       # name + id only
#   scripts/identity/list-auth-profiles/run.sh --filter MFA        # name contains "MFA"
#   scripts/identity/list-auth-profiles/run.sh --filter MFA --names-only

set -euo pipefail

REPO_ROOT="${IDIRA_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"

# shellcheck source=../../../lib/discovery.sh
source "${REPO_ROOT}/lib/discovery.sh"
# shellcheck source=../../../lib/auth.sh
source "${REPO_ROOT}/lib/auth.sh"

# Defaults
NAMES_ONLY=0
FILTER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --names-only)  NAMES_ONLY=1; shift ;;
    --filter)      FILTER="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "run.sh: unknown arg '$1'. See --help." >&2
      exit 2
      ;;
  esac
done

# Discover URLs + log in Service User via ark
_ensure_discovered
ark_service_user_login >/dev/null

# Fetch profiles.
# ark exec identity policies list-authentication-profiles returns a JSON array.
# Output (full): pipe to jq for filtering / projection.
output=$(ark exec --raw identity policies list-authentication-profiles 2>&1)

if [[ -n "$FILTER" ]]; then
  output=$(jq --arg f "$FILTER" '[.[] | select(.Name | test($f; "i"))]' <<<"$output")
fi

if [[ "$NAMES_ONLY" -eq 1 ]]; then
  jq -r '.[] | "\(.Uuid)  \(.Name)"' <<<"$output"
else
  echo "$output" | jq .
fi
