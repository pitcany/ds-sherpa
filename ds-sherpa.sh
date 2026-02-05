#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2016
set -euo pipefail
IFS=$'\n\t'
trap 'echo "ERROR: failed at line $LINENO" >&2' ERR

# ds-sherpa bootstrap for Claude Code (Data Scientist edition)
#
# What this script DOES:
# - Creates a local Claude Code plugin called "ds-sherpa" with:
#   - skills (slash commands): /eda /metric-check /sql /ab-plan /readout /model-plan /feature-audit /review /decision-memo
#   - subagents: experiment-designer, sql-analyst, data-qa, modeling-lead
#   - hooks: blocks dangerous bash, auto-format + lint after edits
#
# What this script DOES NOT do (interactive in Claude Code):
# - Add public marketplaces via "/plugin marketplace add ..."
# - Install/enable the plugin via "/plugin install ..." and "/plugin enable ..."
#
# After running this script, it prints exact slash commands for Claude Code.

# === Argument parsing ===
VERBOSE=0
BACKUP=1
SETUP_ENV=0
PYTHON_BIN=""
VENV_DIR=""
REQUIREMENTS_FILE=""
INSTALL_CORE=0
INSTALL_PYTORCH=0
MCP_WAREHOUSE=0
DRY_RUN=0
INSTALL_PYTORCH_CPU=0
INSTALL_PYTORCH_GPU=0
VERIFY_MCP=0
INSTALL_QUANT=0
INSTALL_QUANT_FULL=0
HAS_JQ=0
INSTALL_DS_FULL=0
USE_CONDA=0
CONDA_ENV_NAME=""
SKILL_DOMAINS="all"

usage() {
  cat <<EOF
Usage: $0 [-v] [-n] [-e] [-c] [-S] [-q] [-Q] [-t] [-T] [-g] [-w] [-D] [-M] [-d domains] [-p python] [-V venv_dir] [-r requirements] [-h] [plugin_dir]

Options:
  -v    Enable verbose output
  -n    Skip backup of existing plugin directory
  -e    Setup Python virtual environment
  -C    Use conda environment instead of venv (requires conda)
  -c    Install core DS packages into venv (pandas, numpy, scipy, scikit-learn, matplotlib, seaborn, statsmodels, jupyterlab, ipykernel)
  -S    Full DS preset (core DS + connectors + notebooks + ML libs)
  -q    Install quant/math packages (mpmath, sympy, numba, cvxpy, arch, linearmodels, gmpy2)
  -Q    Quant full preset (core DS + quant/math)
  -t    Print PyTorch install hints (CPU/CUDA) during env setup
  -T    Install PyTorch CPU-only into venv (safe default)
        Set DS_SHERPA_PYTORCH_CUDA=1 to skip CPU install and show CUDA guidance
  -g    Install PyTorch GPU build (set DS_SHERPA_CUDA=cu118|cu121|cu124)
  -w    Create optional DS warehouse MCP template (uses DS_SHERPA_*_MCP_URL if set)
  -d    Skill domains to install (comma-separated: ds,quant,content; default: all)
  -D    Dry-run (print planned actions, no filesystem writes)
  -M    Verify MCP URLs (no filesystem writes)
  -p    Python executable to use (default: python3)
  -V    Virtualenv directory (default: <plugin_dir>/.venv)
  -r    requirements.txt to install into venv
  -h    Show this help message

Arguments:
  plugin_dir    Target directory (default: ~/.claude/plugins/ds-sherpa)
EOF
}

while getopts "vnh ecp:V:r:twDTMqQgSCd:" opt; do
  case $opt in
    v) VERBOSE=1 ;;
    n) BACKUP=0 ;;
    e) SETUP_ENV=1 ;;
    c) INSTALL_CORE=1 ;;
    p) PYTHON_BIN="$OPTARG" ;;
    V) VENV_DIR="$OPTARG" ;;
    r) REQUIREMENTS_FILE="$OPTARG" ;;
    t) INSTALL_PYTORCH=1 ;;
    w) MCP_WAREHOUSE=1 ;;
    D) DRY_RUN=1 ;;
    T) INSTALL_PYTORCH_CPU=1 ;;
    M) VERIFY_MCP=1 ;;
    q) INSTALL_QUANT=1 ;;
    Q) INSTALL_QUANT_FULL=1 ;;
    g) INSTALL_PYTORCH_GPU=1 ;;
    S) INSTALL_DS_FULL=1 ;;
    C) USE_CONDA=1 ;;
    d) SKILL_DOMAINS="$OPTARG" ;;
    h)
      usage
      exit 0
      ;;
    *)
      echo_err "Unknown option: -$OPTARG"
      echo "Use -h for help"
      exit 1
      ;;
  esac
done

shift $((OPTIND - 1))

PLUGIN_DIR="${1:-$HOME/.claude/plugins/ds-sherpa}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
VENV_DIR="${VENV_DIR:-$PLUGIN_DIR/.venv}"

# === Helper functions (defined early for use in getopts) ===

echo_err() {
  echo "$@" >&2
}

# === Resolve repo root (source of truth for all content files) ===
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

fatal() {
  echo_err "ERROR: $*"
  exit 1
}

check_cmd() {
  local cmd=$1
  if ! command -v "$cmd" &>/dev/null; then
    fatal "Required command '$cmd' not found."
  fi
}

log() {
  if [[ $VERBOSE -eq 1 ]]; then
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $*"
  fi
}

log_step() {
  if [[ $VERBOSE -eq 1 ]]; then
    echo "[STEP] $*"
  fi
}

log_verbose() {
  if [[ $VERBOSE -eq 1 ]]; then
    echo "[DEBUG] $*"
  fi
}

jq_write() {
  local tmp=$1
  local out=$2
  shift 2
  jq "$@" > "$tmp" && mv "$tmp" "$out"
}

# Inject an MCP server entry into a JSON file if URL is set
inject_mcp() {
  local json_file=$1
  local server_name=$2
  local url=$3
  local type=${4:-http}
  local desc=${5:-"$server_name MCP server"}

  if [[ -z "$url" ]]; then
    return 0
  fi

  if [[ $HAS_JQ -eq 1 ]]; then
    jq_write "${json_file}.tmp" "$json_file" \
      --arg name "$server_name" --arg url "$url" --arg type "$type" --arg desc "$desc" \
      '.mcpServers[$name] = {type:$type, url:$url, description:$desc}' \
      "$json_file"
  else
    echo_err "Warning: jq not found; cannot inject $server_name MCP URL"
  fi
}

# === Validate Environment ===

check_cmd mkdir
check_cmd cat
check_cmd chmod
check_cmd "$PYTHON_BIN"
if command -v jq >/dev/null 2>&1; then
  HAS_JQ=1
fi

log_verbose "Plugin directory: $PLUGIN_DIR"
log_verbose "Python: $PYTHON_BIN"
log_verbose "Venv: $VENV_DIR"
log_verbose "Setup env: $SETUP_ENV"
log_verbose "Install core DS: $INSTALL_CORE"
log_verbose "Install PyTorch hints: $INSTALL_PYTORCH"
log_verbose "Warehouse MCP template: $MCP_WAREHOUSE"
log_verbose "Dry-run: $DRY_RUN"
log_verbose "Install PyTorch CPU-only: $INSTALL_PYTORCH_CPU"
log_verbose "Verify MCP URLs: $VERIFY_MCP"
log_verbose "Install quant/math packages: $INSTALL_QUANT"
log_verbose "Install quant full preset: $INSTALL_QUANT_FULL"
log_verbose "jq available: $HAS_JQ"
log_verbose "Install PyTorch GPU: $INSTALL_PYTORCH_GPU"
log_verbose "Install full DS preset: $INSTALL_DS_FULL"
log_verbose "Use conda: $USE_CONDA"

if [[ -e "$PLUGIN_DIR" && ! -w "$PLUGIN_DIR" ]]; then
  fatal "Plugin directory is not writable: $PLUGIN_DIR"
fi

# === OS/package manager hints for core tools ===
detect_os_pkg() {
  local os pkg
  os="$(uname -s 2>/dev/null || echo unknown)"
  case "$os" in
    Darwin)
      pkg="brew"
      ;;
    Linux)
      if command -v apt-get >/dev/null 2>&1; then
        pkg="apt-get"
      elif command -v dnf >/dev/null 2>&1; then
        pkg="dnf"
      elif command -v yum >/dev/null 2>&1; then
        pkg="yum"
      elif command -v pacman >/dev/null 2>&1; then
        pkg="pacman"
      else
        pkg="unknown"
      fi
      ;;
    *)
      pkg="unknown"
      ;;
  esac
  echo "$os:$pkg"
}

print_install_hints() {
  local info os pkg
  info="$(detect_os_pkg)"
  os="${info%%:*}"
  pkg="${info##*:}"

  echo_err "Missing core tools detected. Install hints:"
  case "$pkg" in
    brew)
      echo_err "  brew install python jq rsync"
      echo_err "  # For venv support: python includes venv on macOS"
      ;;
    apt-get)
      echo_err "  sudo apt-get update && sudo apt-get install -y python3 python3-venv jq rsync"
      ;;
    dnf)
      echo_err "  sudo dnf install -y python3 python3-venv jq rsync"
      ;;
    yum)
      echo_err "  sudo yum install -y python3 python3-venv jq rsync"
      ;;
    pacman)
      echo_err "  sudo pacman -S --noconfirm python jq rsync"
      echo_err "  # For venv support: python includes venv on Arch"
      ;;
    *)
      echo_err "  Install: python (with venv), jq, rsync using your OS package manager."
      echo_err "  Required: python3, python3-venv (or python-venv), jq, rsync"
      ;;
  esac
}

print_quant_hints() {
  local info os pkg
  info="$(detect_os_pkg)"
  os="${info%%:*}"
  pkg="${info##*:}"

  echo_err "Quant/math stack hints (system libraries for high-performance math):"
  case "$pkg" in
    brew)
      echo_err "  brew install openblas lapack gfortran"
      ;;
    apt-get)
      echo_err "  sudo apt-get install -y build-essential gfortran libopenblas-dev liblapack-dev"
      ;;
    dnf)
      echo_err "  sudo dnf install -y gcc gcc-gfortran openblas-devel lapack-devel"
      ;;
    yum)
      echo_err "  sudo yum install -y gcc gcc-gfortran openblas-devel lapack-devel"
      ;;
    pacman)
      echo_err "  sudo pacman -S --noconfirm base-devel openblas lapack"
      ;;
    *)
      echo_err "  Install BLAS/LAPACK + Fortran toolchain via your OS package manager."
      ;;
  esac
}

missing_core=0
for tool in "$PYTHON_BIN" jq rsync; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo_err "Missing tool: $tool"
    missing_core=1
  fi
done
if ! "$PYTHON_BIN" -m venv -h >/dev/null 2>&1; then
  echo_err "Missing Python venv module for: $PYTHON_BIN"
  missing_core=1
fi
if [[ $missing_core -eq 1 ]]; then
  print_install_hints
fi

if ! "$PYTHON_BIN" - <<'PY' >/dev/null 2>&1; then
import sys
sys.exit(0 if sys.version_info[:2] >= (3, 9) else 1)
PY
  echo_err "Warning: Python < 3.9 detected. Prefer Python 3.10–3.12 for modern DS tooling."
fi

verify_url() {
  local url=$1
  local name=$2
  local header=${3:-}
  if ! command -v curl >/dev/null 2>&1; then
    echo_err "curl not found; cannot verify MCP URLs."
    return 1
  fi
  if [[ -n "$header" ]]; then
    if curl -fsS -m 5 -H "$header" "$url" >/dev/null 2>&1; then
      log_verbose "MCP OK: $name"
    else
      echo_err "MCP verify failed: $name ($url)"
    fi
  else
    if curl -fsS -m 5 "$url" >/dev/null 2>&1; then
      log_verbose "MCP OK: $name"
    else
      echo_err "MCP verify failed: $name ($url)"
    fi
  fi
}

if [[ $VERIFY_MCP -eq 1 ]]; then
  echo "Verifying MCP URLs (no writes)..."
  if ! command -v curl >/dev/null 2>&1; then
    echo_err "curl not found; cannot verify MCP URLs."
    exit 1
  fi
  verify_url "https://bigquery.googleapis.com/mcp" "bigquery"
  if [[ "${DS_SHERPA_NOTION_MCP_SSE:-0}" -eq 1 ]]; then
    verify_url "https://mcp.notion.com/sse" "notion (sse)"
  else
    verify_url "https://mcp.notion.com/mcp" "notion"
  fi
  verify_url "https://mcp.supabase.com/mcp" "supabase"
  verify_url "https://mcp.linear.app/mcp" "linear"
  verify_url "https://api.greptile.com/mcp" "greptile"
  if [[ -n "${GITHUB_MCP_PAT:-}" ]]; then
    verify_url "https://api.githubcopilot.com/mcp/" "github" "Authorization: Bearer ${GITHUB_MCP_PAT}"
  else
    echo_err "Skipping GitHub MCP verify: GITHUB_MCP_PAT not set"
  fi
  exit 0
fi

if [[ $DRY_RUN -eq 1 ]]; then
  echo "Dry-run enabled. Planned actions:"
  echo "  - Create plugin dir: $PLUGIN_DIR"
  echo "  - Write plugin.json, hooks.json, skills, agents, scripts"
  echo "  - Write commands and MCP templates"
  if [[ $MCP_WAREHOUSE -eq 1 ]]; then
    echo "  - Write optional warehouse MCP template"
  fi
  if [[ $SETUP_ENV -eq 1 ]]; then
    echo "  - Create venv: $VENV_DIR"
    echo "  - Use conda: $USE_CONDA"
    echo "  - Install core DS packages: $INSTALL_CORE"
    echo "  - Install full DS preset: $INSTALL_DS_FULL"
    echo "  - Install requirements: ${REQUIREMENTS_FILE:-<none>}"
    echo "  - Install PyTorch CPU-only: $INSTALL_PYTORCH_CPU"
    echo "  - Install PyTorch GPU: $INSTALL_PYTORCH_GPU"
    echo "  - Install quant/math packages: $INSTALL_QUANT"
    echo "  - Install quant full preset: $INSTALL_QUANT_FULL"
  fi
  exit 0
fi

# Backup existing plugin directory if it exists and is not empty
copy_dir() {
  local src=$1
  local dst=$2

  if command -v rsync >/dev/null 2>&1; then
    rsync -a "$src"/ "$dst"/
    return
  fi

  if cp -a "$src" "$dst" 2>/dev/null; then
    return
  fi

  cp -r "$src" "$dst"
}

if [[ -d "$PLUGIN_DIR" && "$(ls -A "$PLUGIN_DIR")" ]]; then
  if [[ $BACKUP -eq 1 ]]; then
    BACKUP_DIR="${PLUGIN_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    log "Backing up existing plugin directory to: $BACKUP_DIR"
    if copy_dir "$PLUGIN_DIR" "$BACKUP_DIR"; then
      log_verbose "Backup created successfully"
    else
      echo_err "Warning: Failed to create backup. Continuing without backup."
    fi
  else
    echo_err "Warning: Plugin directory '$PLUGIN_DIR' already exists and is not empty. Files may be overwritten (backup skipped)."
  fi
fi

# === Validation functions ===

validate_json_file() {
  local file=$1
  local desc=${2:-JSON file}

  if [[ ! -f "$file" ]]; then
    echo_err "Validation failed: $desc not found at $file"
    return 1
  fi

  if [[ $HAS_JQ -eq 1 ]]; then
    if ! jq empty "$file" 2>/dev/null; then
      echo_err "Validation failed: $desc is not valid JSON: $file"
      return 1
    fi
  else
    echo_err "Warning: jq not found, skipping $desc validation"
  fi

  log_verbose "$desc validated: $file"
  return 0
}

validate_skill_files() {
  for domain_dir in "$REPO_ROOT"/skills/*/; do
    for skill_dir in "$domain_dir"/*/; do
      [[ -d "$skill_dir" ]] || continue
      local skill="$(basename "$skill_dir")"
      local skill_file="$PLUGIN_DIR/skills/$skill/SKILL.md"
      if [[ ! -f "$skill_file" ]]; then
        # Only warn if domain was selected
        log_verbose "Skill not installed (domain not selected): $skill"
      else
        log_verbose "Skill file exists: $skill_file"
      fi
    done
  done
}

validate_agent_files() {
  local missing=0
  for agent_file in "$REPO_ROOT"/agents/*.md; do
    local agent="$(basename "$agent_file" .md)"
    local dest="$PLUGIN_DIR/agents/$agent.md"
    if [[ ! -f "$dest" ]]; then
      echo_err "Missing agent file: $dest"
      ((missing++))
    else
      log_verbose "Agent file exists: $dest"
    fi
  done

  if [[ $missing -gt 0 ]]; then
    fatal "$missing agent files missing"
  fi
}

validate_hook_scripts() {
  local missing=0
  local not_exec=0

  for script in guard_bash.py format_after_edit.sh lint_after_edit.sh; do
    local script_path="$PLUGIN_DIR/scripts/$script"
    if [[ ! -f "$script_path" ]]; then
      echo_err "Missing hook script: $script_path"
      ((missing++))
    elif [[ ! -x "$script_path" ]]; then
      echo_err "Hook script not executable: $script_path"
      ((not_exec++))
    else
      log_verbose "Hook script validated: $script_path"
    fi
  done

  if [[ $missing -gt 0 ]]; then
    fatal "$missing hook scripts missing"
  fi

  if [[ $not_exec -gt 0 ]]; then
    fatal "$not_exec hook scripts not executable"
  fi
}

log_step "Creating directory structure..."
mkdir -p "$PLUGIN_DIR"/{.claude-plugin,skills,agents,hooks,scripts}
mkdir -p "$PLUGIN_DIR"/{commands,mcp-servers,templates}
# Skills subdirs are created during copy
log_verbose "Directory structure created"

# === Write plugin.json with validation ===
log_step "Writing plugin.json..."
plugin_json="$PLUGIN_DIR/.claude-plugin/plugin.json"

if [[ $HAS_JQ -eq 1 ]]; then
  # Build base plugin.json then merge mcpServers from ds-mcp.json
  cat > "$plugin_json" <<'JSON'
{
  "name": "ds-sherpa",
  "version": "0.1.0",
  "description": "Data-science workflows: experiments, metrics, SQL, EDA, review + safety hooks.",
  "author": { "name": "local" },
  "skills": "./skills",
  "agents": "./agents",
  "hooks": "./hooks/hooks.json"
}
JSON

  # Merge mcpServers from ds-mcp.json (single source of truth)
  jq -s '.[0] * {mcpServers: .[1].mcpServers}' \
    "$plugin_json" "$REPO_ROOT/mcp-servers/ds-mcp.json" > "$plugin_json.tmp" \
    && mv "$plugin_json.tmp" "$plugin_json"

  if ! jq empty "$plugin_json"; then
    fatal "Generated plugin.json is invalid!"
  fi
  log_verbose "plugin.json validated (mcpServers merged from ds-mcp.json)"
else
  echo_err "Warning: jq not found, writing plugin.json without mcpServers"
  cat > "$plugin_json" <<'JSON'
{
  "name": "ds-sherpa",
  "version": "0.1.0",
  "description": "Data-science workflows: experiments, metrics, SQL, EDA, review + safety hooks.",
  "author": { "name": "local" },
  "skills": "./skills",
  "agents": "./agents",
  "hooks": "./hooks/hooks.json"
}
JSON
fi

if [[ ! -d "$REPO_ROOT/skills" ]]; then
  fatal "Cannot find skills/ directory. Run this script from the cloned ds-sherpa repo."
fi

# === Determine which skill domains to install ===
if [[ "$SKILL_DOMAINS" == "all" ]]; then
  domains=()
  for d in "$REPO_ROOT"/skills/*/; do
    [[ -d "$d" ]] && domains+=("$(basename "$d")")
  done
else
  IFS=',' read -ra domains <<< "$SKILL_DOMAINS"
fi
log_verbose "Skill domains: ${domains[*]}"

# === Copy skills from repo (flat output, no domain prefix) ===
log_step "Copying skills..."

skill_count=0
for domain in "${domains[@]}"; do
  domain_dir="$REPO_ROOT/skills/$domain"
  if [[ ! -d "$domain_dir" ]]; then
    echo_err "Warning: skill domain '$domain' not found in $REPO_ROOT/skills/, skipping"
    continue
  fi
  for skill_dir in "$domain_dir"/*/; do
    [[ -d "$skill_dir" ]] || continue
    skill="$(basename "$skill_dir")"
    mkdir -p "$PLUGIN_DIR/skills/$skill"
    cp "$skill_dir/SKILL.md" "$PLUGIN_DIR/skills/$skill/SKILL.md"
    log_verbose "Skill copied: $domain/$skill -> skills/$skill"
    ((skill_count++))
  done
done
log_verbose "$skill_count skills copied"

# === Copy agents from repo ===
log_step "Copying agents..."

agent_count=0
cp "$REPO_ROOT"/agents/*.md "$PLUGIN_DIR/agents/"
for f in "$PLUGIN_DIR"/agents/*.md; do
  log_verbose "Agent copied: $(basename "$f" .md)"
  ((agent_count++))
done
log_verbose "$agent_count agents copied"

# === Copy commands from repo ===
log_step "Copying commands..."

cmd_count=0
cp "$REPO_ROOT"/commands/*.md "$PLUGIN_DIR/commands/"
for f in "$PLUGIN_DIR"/commands/*.md; do
  log_verbose "Command copied: $(basename "$f" .md)"
  ((cmd_count++))
done
log_verbose "$cmd_count commands copied"

# === Copy scripts from repo ===
log_step "Copying scripts..."

cp "$REPO_ROOT"/scripts/* "$PLUGIN_DIR/scripts/"
chmod +x "$PLUGIN_DIR/scripts/"*.sh "$PLUGIN_DIR/scripts/"*.py 2>/dev/null || true
chmod +x "$PLUGIN_DIR/scripts/_common.sh" 2>/dev/null || true
log_verbose "Scripts copied and permissions set"

validate_hook_scripts

# === Copy MCP server templates from repo ===
log_step "Copying MCP templates..."

cp "$REPO_ROOT"/mcp-servers/ds-mcp.json "$PLUGIN_DIR/mcp-servers/ds-mcp.json"
validate_json_file "$PLUGIN_DIR/mcp-servers/ds-mcp.json" "ds-mcp.json"

# Runtime MCP mutations (these need env vars so can't be static files)
if [[ "${DS_SHERPA_NOTION_MCP_SSE:-0}" -eq 1 && $HAS_JQ -eq 1 ]]; then
  jq_write "$PLUGIN_DIR/mcp-servers/.ds-mcp.tmp" "$PLUGIN_DIR/mcp-servers/ds-mcp.json" \
    '.mcpServers.notion.type="sse" | .mcpServers.notion.url="https://mcp.notion.com/sse" | .mcpServers.notion.description="Notion MCP (SSE)"' \
    "$PLUGIN_DIR/mcp-servers/ds-mcp.json"
elif [[ "${DS_SHERPA_NOTION_MCP_SSE:-0}" -eq 1 ]]; then
  echo_err "Warning: jq not found; cannot switch Notion MCP to SSE"
fi

inject_mcp "$PLUGIN_DIR/mcp-servers/ds-mcp.json" "slack" "${DS_SHERPA_SLACK_MCP_URL:-}" "sse"

if [[ $MCP_WAREHOUSE -eq 1 ]]; then
  cat > "$PLUGIN_DIR/mcp-servers/ds-mcp-warehouses.json" <<'JSON'
{
  "mcpServers": {
    "bigquery": {
      "type": "http",
      "url": "https://bigquery.googleapis.com/mcp",
      "description": "BigQuery MCP server (Google Cloud)"
    }
  }
}
JSON

  wh_json="$PLUGIN_DIR/mcp-servers/ds-mcp-warehouses.json"
  inject_mcp "$wh_json" "snowflake"  "${DS_SHERPA_SNOWFLAKE_MCP_URL:-}"
  inject_mcp "$wh_json" "databricks" "${DS_SHERPA_DATABRICKS_MCP_URL:-}"
  inject_mcp "$wh_json" "redshift"   "${DS_SHERPA_REDSHIFT_MCP_URL:-}"
  inject_mcp "$wh_json" "s3"         "${DS_SHERPA_S3_MCP_URL:-}"
  inject_mcp "$wh_json" "gcs"        "${DS_SHERPA_GCS_MCP_URL:-}"

  validate_json_file "$PLUGIN_DIR/mcp-servers/ds-mcp-warehouses.json" "ds-mcp-warehouses.json"
fi

# === Copy templates from repo ===
log_step "Copying templates..."

cp "$REPO_ROOT"/templates/* "$PLUGIN_DIR/templates/"
log_verbose "Templates copied"

# === Generate hooks.json from template ===
: "${CLAUDE_PLUGIN_ROOT:=$PLUGIN_DIR}"

log_step "Generating hooks.json from template..."

hooks_file="$PLUGIN_DIR/hooks/hooks.json"
exfil_allowlist="${DS_SHERPA_EXFIL_ALLOWLIST:-localhost,127.0.0.1,0.0.0.0}"

sed -e "s|__PLUGIN_DIR__|${CLAUDE_PLUGIN_ROOT}|g" \
    -e "s|__EXFIL_ALLOWLIST__|${exfil_allowlist}|g" \
    "$REPO_ROOT/hooks/hooks.json.tmpl" > "$hooks_file"

validate_json_file "$hooks_file" "hooks.json"

# === Optional env setup ===
setup_env() {
  log_step "Setting up Python virtual environment..."

  if [[ $USE_CONDA -eq 1 ]]; then
    check_cmd conda
    CONDA_ENV_NAME="${CONDA_ENV_NAME:-ds-sherpa}"
    conda create -y -n "$CONDA_ENV_NAME" python
    # shellcheck disable=SC1091
    source "$(conda info --base)/etc/profile.d/conda.sh"
    conda activate "$CONDA_ENV_NAME"
    python -m pip install --upgrade pip setuptools wheel
  else
    if ! "$PYTHON_BIN" -m venv "$VENV_DIR" 2>/dev/null; then
      echo_err "Failed to create venv with $PYTHON_BIN."
      echo_err "Ensure the Python venv module is installed (e.g., python3-venv)."
      fatal "venv creation failed"
    fi

    # shellcheck disable=SC1091
    source "$VENV_DIR/bin/activate"

    if ! python -m pip --version >/dev/null 2>&1; then
      python -m ensurepip --upgrade
    fi

    python -m pip install --upgrade pip setuptools wheel
  fi

  if [[ $INSTALL_DS_FULL -eq 1 ]]; then
    INSTALL_CORE=1
  fi

  if [[ $INSTALL_QUANT_FULL -eq 1 ]]; then
    INSTALL_CORE=1
    INSTALL_QUANT=1
  fi

  if [[ $INSTALL_CORE -eq 1 ]]; then
    pip install pandas numpy scipy scikit-learn matplotlib seaborn statsmodels jupyterlab ipykernel
  fi

  if [[ $INSTALL_DS_FULL -eq 1 ]]; then
    pip install sqlalchemy psycopg2-binary pyarrow duckdb boto3 s3fs gcsfs \
      google-cloud-bigquery snowflake-connector-python ipywidgets jupyterlab-lsp nbconvert \
      xgboost lightgbm catboost
  fi

  if [[ $INSTALL_QUANT -eq 1 ]]; then
    print_quant_hints
    pip install numpy scipy mpmath sympy numba cvxpy arch linearmodels gmpy2
  fi

  if [[ $INSTALL_PYTORCH -eq 1 ]]; then
    echo "PyTorch install hints:"
    echo "  CPU-only:  pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu"
    echo "  CUDA:      see https://pytorch.org/get-started/locally/ and pick your CUDA version"
  fi

  if [[ $INSTALL_PYTORCH_CPU -eq 1 ]]; then
    if [[ "${DS_SHERPA_PYTORCH_CUDA:-0}" -eq 1 ]]; then
      echo "CUDA install requested. Use https://pytorch.org/get-started/locally/ to select the correct command."
    else
      pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
    fi
  fi

  if [[ $INSTALL_PYTORCH_GPU -eq 1 ]]; then
    case "${DS_SHERPA_CUDA:-}" in
      cu118|cu121|cu124)
        pip install torch torchvision torchaudio --index-url "https://download.pytorch.org/whl/${DS_SHERPA_CUDA}"
        ;;
      *)
        fatal "Set DS_SHERPA_CUDA to cu118, cu121, or cu124 for GPU install"
        ;;
    esac
  fi

  if [[ -n "$REQUIREMENTS_FILE" ]]; then
    if [[ -f "$REQUIREMENTS_FILE" ]]; then
      pip install -r "$REQUIREMENTS_FILE"
    else
      fatal "requirements file not found: $REQUIREMENTS_FILE"
    fi
  else
    log "No requirements file provided; venv created and pip updated."
  fi
}

if [[ $SETUP_ENV -eq 1 ]]; then
  setup_env
fi

# === Final validation summary ===
log_step "Running final validation..."
if [[ $VERBOSE -eq 1 ]]; then
  echo ""
  echo "=== Validation Summary ==="
  echo "✓ plugin.json: valid"
  echo "✓ hooks.json: valid"
  echo "✓ Skills: $skill_count copied"
  echo "✓ Agents: $agent_count copied"
  echo "✓ Hook scripts: 3 created and executable"
  echo ""
fi

# === Final output instructions ===

printf '\n✅ ds-sherpa scaffold created at:\n  %s\n\n' "$PLUGIN_DIR"
printf 'Next steps (paste these INSIDE Claude Code):\n\n'
printf '1) Install + enable the plugin:\n   /plugin install %s\n   /plugin enable ds-sherpa\n\n' "$PLUGIN_DIR"
cat <<'EOF'

2) Add public marketplaces (optional but recommended):
   /plugin marketplace add anthropics/claude-plugins-official
   /plugin marketplace add obra/superpowers-marketplace
   /plugin marketplace add feed-mob/claude-code-marketplace
   /plugin marketplace add netresearch/claude-code-marketplace
   /plugin marketplace add aimoda/claude-code-plugin-marketplace

3) Try your new commands:
   DS: /eda /metric-check /sql /ab-plan /readout /model-plan /feature-audit /review /decision-memo
   Quant: /factor-lab /risk-check /options-notes /backtest-plan /trade-memo
   Research: /research /summary
   Content: /content-plan /hook /script /caption /repurpose /newsletter /seo-brief /thumbnail-brief
   Ops: /ds-mcp-setup /ds-mcp-merge /ds-env-setup /ds-sql-check /ds-qa-report /ds-eda-brief /ds-claude-template /ds-exfil-allowlist

4) (Optional) Enable DS MCPs in a repo:
   - Run \`/ds-mcp-setup\` inside Claude Code in that repo
   - Or use \`/ds-mcp-merge\` to merge into an existing \`mcp.json\`
   - Then edit \`mcp.json\` to keep only the MCPs you need
   - For additional MCPs: set \`DS_SHERPA_SLACK_MCP_URL\` and/or \`DS_SHERPA_*_MCP_URL\` before running the script with \`-w\`

5) (Optional) Scope format/lint to specific files:
   - Set \`DS_SHERPA_TARGETS\` or \`CLAUDE_EDITED_PATHS\` to space-separated paths
   - Set \`DS_SHERPA_RUN_PYTEST=1\` to enable scoped pytest runs
   - Exfil guard allowlist (default: localhost): \`DS_SHERPA_EXFIL_ALLOWLIST\`
   - Install allowlist template: \`/ds-exfil-allowlist\`
   - High-risk ops require confirmation token: \`DS_SHERPA_CONFIRM_TOKEN\` (default: \`--YES-I-KNOW\`)

Tip: Put a project-specific file at .claude/CLAUDE.md in each repo to define your metric names, table grains, and conventions.

EOF
