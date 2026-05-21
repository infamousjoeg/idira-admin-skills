#!/usr/bin/env bash
# lib/tf-wrap.sh — wraps terraform init/plan/apply for a captured module.
#
# Usage:
#   lib/tf-wrap.sh plan   <module-path> [-var=KEY=VAL ...]
#   lib/tf-wrap.sh apply  <module-path> [-var=KEY=VAL ...]   # runs plan first, shows diff, confirms
#   lib/tf-wrap.sh destroy <module-path> --apply-destroy [-var=KEY=VAL ...]
#
# <module-path> may be:
#   tf/<area>/<op>/                      — promoted module
#   _inbox/<draft-dir>/                  — inbox draft
#   any absolute or relative path to a directory containing main.tf

set -euo pipefail

_TFW_REPO_ROOT="${IDIRA_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)}"

# shellcheck source=discovery.sh
source "${_TFW_REPO_ROOT}/lib/discovery.sh"
# shellcheck source=auth.sh
source "${_TFW_REPO_ROOT}/lib/auth.sh"
# shellcheck source=capture.sh
source "${_TFW_REPO_ROOT}/lib/capture.sh"

action="${1:?tf-wrap.sh: action required (plan|apply|destroy)}"
shift
module="${1:?tf-wrap.sh: module path required}"
shift

# Resolve module to an absolute path, prefixing tf/ if it's a bare area/op.
if [[ ! -d "$module" ]]; then
  if [[ -d "${_TFW_REPO_ROOT}/tf/${module}" ]]; then
    module="${_TFW_REPO_ROOT}/tf/${module}"
  else
    echo "tf-wrap.sh: module not found at '$module' or '${_TFW_REPO_ROOT}/tf/${module}'" >&2
    exit 1
  fi
fi
module="$(cd "$module" && pwd)"

# Compute a stable state path under state/<area>/<op>/ for non-inbox modules,
# state/_inbox/<draft>/ for inbox drafts.
relpath="${module#"${_TFW_REPO_ROOT}"/}"
state_dir="${_TFW_REPO_ROOT}/state/${relpath#tf/}"
mkdir -p "$state_dir"

# Discover URLs + load Service User auth for the providers.
_ensure_discovered

# Pre-flight: prefer `tofu` (OpenTofu) if available — newer, MPL-2.0, drop-in for terraform.
# Fall back to `terraform`. Bail with install hint if neither is present.
if command -v tofu >/dev/null 2>&1; then
  TF_BIN="tofu"
elif command -v terraform >/dev/null 2>&1; then
  TF_BIN="terraform"
else
  echo "tf-wrap.sh: neither tofu nor terraform on PATH. Install via:" >&2
  echo "  brew install opentofu          # recommended (MPL-2.0)" >&2
  echo "  # or:" >&2
  echo "  https://developer.hashicorp.com/terraform/install" >&2
  exit 127
fi

# Best-effort: peek at versions.tf for the primary provider name (for audit log tag).
_tfw_provider_used() {
  if [[ -f "${module}/versions.tf" ]]; then
    grep -oE 'source\s*=\s*"cyberark/[a-z]+"' "${module}/versions.tf" | head -1 | sed -E 's/.*"(cyberark\/[a-z]+)".*/\1/'
  else
    echo "unknown"
  fi
}

# Slug for audit logging.
op_slug="${relpath#tf/}"
op_slug="${op_slug%/}"

# Build provider env. cyberark/idsec consumes ARK_* or specific env vars (TBD per provider docs).
# This block is the integration point — refine per the provider's auth.go conventions.
_auth_load_credentials  # populates CYBERARK_SERVICE_USER + _SECRET in-process; never to disk
export ARK_USERNAME="$CYBERARK_SERVICE_USER"
export ARK_SECRET="$CYBERARK_SERVICE_USER_SECRET"
# (When cyberark/idsec/conjur/cyberark provider env-var names are fully confirmed against their
#  docs, add provider-specific exports here. For now, ARK_USERNAME/ARK_SECRET cover most.)

cd "$module"

case "$action" in
  plan)
    "$TF_BIN" init -backend=false -input=false -no-color >&2
    "$TF_BIN" plan -input=false -no-color "$@"
    ;;

  apply)
    "$TF_BIN" init -input=false -no-color >&2
    echo "tf-wrap.sh: running plan first…" >&2
    "$TF_BIN" plan -out=tfplan -input=false -no-color "$@" >&2
    echo "" >&2
    read -r -p "Apply this plan? [y/N] " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo "tf-wrap.sh: aborted." >&2
      rm -f tfplan
      exit 1
    fi
    "$TF_BIN" apply -input=false -no-color tfplan
    rm -f tfplan
    capture_audit "$op_slug" "terraform:$(_tfw_provider_used)" "{}" "applied"
    ;;

  destroy)
    if [[ "${1:-}" != "--apply-destroy" ]]; then
      echo "tf-wrap.sh: destroy requires --apply-destroy flag." >&2
      exit 1
    fi
    shift
    "$TF_BIN" init -input=false -no-color >&2
    echo "tf-wrap.sh: planning destroy…" >&2
    "$TF_BIN" plan -destroy -out=tfplan -input=false -no-color "$@" >&2
    echo "" >&2
    read -r -p "DESTROY these resources? [type 'yes I am sure'] " confirm
    if [[ "$confirm" != "yes I am sure" ]]; then
      echo "tf-wrap.sh: aborted." >&2
      rm -f tfplan
      exit 1
    fi
    "$TF_BIN" apply -input=false -no-color tfplan
    rm -f tfplan
    capture_audit "$op_slug" "terraform:$(_tfw_provider_used)" "{}" "destroyed"
    ;;

  *)
    echo "tf-wrap.sh: unknown action '$action' (plan|apply|destroy)" >&2
    exit 2
    ;;
esac
