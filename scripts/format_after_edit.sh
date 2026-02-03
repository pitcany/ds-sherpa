#!/usr/bin/env bash
set -euo pipefail

# Run code formatters quickly if available in this directory or higher.
# Logs errors but does not fail to avoid blocking edits.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$SCRIPT_DIR/_common.sh"

run_tool "format" ruff format
run_tool "format" black
run_tool "format" prettier -w

exit 0
