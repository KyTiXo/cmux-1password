#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")" \
  || exit 1

# ------------------------------------------------------------------------------

require_cmd() {
  command -v "$1" &> /dev/null || {
    echo "missing command: $1" >&2
    exit 1
  }
}

run() {
  echo
  echo "\$ $*"
  "$@"
}

# ------------------------------------------------------------------------------

require_cmd cmux

[[ -n "${CMUX_WORKSPACE_ID:-}" ]] || {
  echo "CMUX_WORKSPACE_ID is missing. Run inside a cmux terminal." >&2
  exit 1
}

[[ -n "${CMUX_SURFACE_ID:-}" ]] || {
  echo "CMUX_SURFACE_ID is missing. Run inside a cmux surface." >&2
  exit 1
}

cleanup="${1:-}"

run cmux ping
run cmux identify --json
run cmux current-workspace --json
run cmux new-split left
sleep 1
run cmux identify --json
run cmux rename-tab "1Password Smoke"
run cmux set-status onepassword-smoke "needs attention" --icon lock --color "#ff9500"
run cmux set-progress 0.5 --label "1Password pending"
run cmux notify --title "1Password Smoke" --subtitle "cmux" --body "Workspace flag set"
run cmux sidebar-state --workspace "$CMUX_WORKSPACE_ID"
run cmux list-status --workspace "$CMUX_WORKSPACE_ID"
run cmux list-panes --workspace "$CMUX_WORKSPACE_ID"
run cmux list-pane-surfaces --workspace "$CMUX_WORKSPACE_ID"
run cmux surface-health --workspace "$CMUX_WORKSPACE_ID"

if [[ "$cleanup" == "--cleanup" ]]; then
  run cmux clear-status onepassword-smoke
  run cmux clear-progress
fi

echo
echo "done"
