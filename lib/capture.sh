#!/usr/bin/env bash
# lib/capture.sh — helpers used by the `idira-capture` skill when drafting to _inbox/
# and the `idira-admin-router` skill when appending audit entries.

set -uo pipefail

_CAPTURE_REPO_ROOT="${IDIRA_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)}"

# capture_new_draft <slug> — creates _inbox/<UTC-ts>-<slug>/ and prints the path.
capture_new_draft() {
  local slug="${1:?capture_new_draft: slug required}"
  local ts
  ts=$(date -u +%Y-%m-%d-%H%M)
  local dir="${_CAPTURE_REPO_ROOT}/_inbox/${ts}-${slug}"
  mkdir -p "$dir"
  echo "$dir"
}

# capture_audit <op> <tool> <params-json> <result> — append JSONL entry.
capture_audit() {
  local op="${1:?capture_audit: op required}"
  local tool="${2:?capture_audit: tool required}"
  local params="${3:-{}}"
  local result="${4:-applied}"

  local audit_dir="${_CAPTURE_REPO_ROOT}/audit"
  mkdir -p "$audit_dir"

  local date_str ts subdomain
  date_str=$(date -u +%Y-%m-%d)
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  subdomain="${CYBERARK_TENANT_SUBDOMAIN:-unknown}"

  jq -nc \
    --arg ts "$ts" \
    --arg op "$op" \
    --arg tool "$tool" \
    --argjson params "$params" \
    --arg result "$result" \
    --arg subdomain "$subdomain" \
    '{ts: $ts, op: $op, tool: $tool, params: $params, result: $result, subdomain: $subdomain}' \
    >> "${audit_dir}/${date_str}.jsonl"
}

# If invoked directly (not sourced), dispatch on subcommand.
if ! (return 0 2>/dev/null); then
  case "${1:-}" in
    new-draft) shift; capture_new_draft "$@" ;;
    audit)     shift; capture_audit "$@" ;;
    *)
      echo "Usage: capture.sh {new-draft <slug> | audit <op> <tool> <params-json> <result>}" >&2
      exit 2
      ;;
  esac
fi
