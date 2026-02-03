#!/usr/bin/env bash
set -euo pipefail

# Run linters/tests quietly if available.
# Logs errors but does not fail to avoid blocking edits.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$SCRIPT_DIR/_common.sh"

run_tool "lint" ruff check
run_tool "lint" mypy
if [[ "${DS_SHERPA_RUN_PYTEST:-0}" -eq 1 ]]; then
  run_tool "lint" pytest -q
fi

exit 0
