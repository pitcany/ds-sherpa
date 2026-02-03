#!/usr/bin/env bash
# Shared helpers for ds-sherpa hook scripts.
# Source this file; do not execute directly.

set -euo pipefail

log_msg() {
  local prefix=$1
  shift
  echo "[$prefix] $*" >&2
}

local_bin() {
  local exe=$1
  if [[ -x "./.venv/bin/$exe" ]]; then
    echo "./.venv/bin/$exe"
    return
  fi
  if [[ -x "./node_modules/.bin/$exe" ]]; then
    echo "./node_modules/.bin/$exe"
    return
  fi
  echo ""
}

collect_targets() {
  if [[ -n "${DS_SHERPA_TARGETS:-}" ]]; then
    echo "${DS_SHERPA_TARGETS}"
    return
  fi
  if [[ -n "${CLAUDE_EDITED_PATHS:-}" ]]; then
    echo "${CLAUDE_EDITED_PATHS}"
    return
  fi
  if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git diff --name-only --diff-filter=ACMRT -- .
    return
  fi
  echo ""
}

# run_tool <prefix> <exe> [args...]
# Looks up exe via local_bin, collects targets, runs <exe> [args...] <targets>.
run_tool() {
  local prefix=$1
  local exe=$2
  shift 2
  local path
  path="$(local_bin "$exe")"
  local targets
  targets="$(collect_targets)"

  if [[ -n "$path" ]]; then
    if [[ -z "$targets" ]]; then
      log_msg "$prefix" "$exe not run (no targets detected)"
      return
    fi
    if ! "$path" "$@" $targets 2>&1 | while read -r line; do
      log_msg "$prefix" "$exe: $line"
    done; then
      log_msg "$prefix" "$exe encountered errors (continuing anyway)"
    fi
  else
    log_msg "$prefix" "$exe not run (no local executable found)"
  fi
}
