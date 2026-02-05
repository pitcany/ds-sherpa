#!/usr/bin/env bash
# ds-sherpa uninstall script
set -euo pipefail

PLUGIN_DIR="${1:-$HOME/.claude/plugins/ds-sherpa}"
REMOVE_BACKUPS=0
REMOVE_VENV=0

usage() {
  cat <<EOF
Usage: $0 [-b] [-v] [plugin_dir]

Options:
  -b    Also remove backup directories (ds-sherpa.backup.*)
  -v    Also remove the .venv directory inside the plugin
  -h    Show this help message

Arguments:
  plugin_dir    Plugin directory (default: ~/.claude/plugins/ds-sherpa)

After running this script, execute inside Claude Code:
  /plugin disable ds-sherpa
  /plugin uninstall ds-sherpa
EOF
}

while getopts "bvh" opt; do
  case $opt in
    b) REMOVE_BACKUPS=1 ;;
    v) REMOVE_VENV=1 ;;
    h) usage; exit 0 ;;
    *) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

PLUGIN_DIR="${1:-$HOME/.claude/plugins/ds-sherpa}"

if [[ ! -d "$PLUGIN_DIR" ]]; then
  echo "Plugin directory not found: $PLUGIN_DIR"
  exit 0
fi

echo "This will remove: $PLUGIN_DIR"
if [[ $REMOVE_BACKUPS -eq 1 ]]; then
  echo "Also removing backups: ${PLUGIN_DIR}.backup.*"
fi
if [[ $REMOVE_VENV -eq 1 ]]; then
  echo "Also removing venv: $PLUGIN_DIR/.venv"
fi

read -rp "Continue? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi

# Remove venv first if requested (it's inside plugin dir, but be explicit)
if [[ $REMOVE_VENV -eq 1 && -d "$PLUGIN_DIR/.venv" ]]; then
  echo "Removing venv..."
  rm -rf "$PLUGIN_DIR/.venv"
fi

echo "Removing plugin directory..."
rm -rf "$PLUGIN_DIR"

if [[ $REMOVE_BACKUPS -eq 1 ]]; then
  echo "Removing backups..."
  rm -rf "${PLUGIN_DIR}.backup."*
fi

cat <<'EOF'

✅ ds-sherpa removed.

Next steps (run inside Claude Code):
  /plugin disable ds-sherpa
  /plugin uninstall ds-sherpa

EOF
