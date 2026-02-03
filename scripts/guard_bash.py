#!/usr/bin/env python3
import json
import re
import sys
import os

payload = json.load(sys.stdin)
cmd = (payload.get("tool_input") or {}).get("command", "") or ""

danger_patterns = [
    r"\brm\s+-rf\b",
    r"\bmkfs\b",
    r"\bdd\s+if=",
    r"\bshutdown\b",
    r"\breboot\b",
    r"\bchown\s+-R\b\s+/\b",
    r"\bchmod\s+-R\b\s+7[0-7]{2}\b\s+/\b",
    r"\b(kill\s+-9|pkill)\b.*\b(claude|terminal|zsh|bash)\b",
    r"\bgit\s+clean\s+-x?d?f\b",
    r"\bfind\b.*\b-delete\b",
    r"\bshred\b",
    r"\btruncate\s+-s\s+0\b",
    r"\b:?\s*>\s*/(etc|var|usr|home|opt)\b",
    r"\brm\s+-rf\b\s+(~|/home|/Users|/data|/datasets|/mnt|/Volumes)\b",
]

secret_patterns = [
    r"(AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|ABIA[0-9A-Z]{16}|ACCA[0-9A-Z]{16}|AIDA[0-9A-Z]{16}|AROA[0-9A-Z]{16}|APKA[0-9A-Z]{16})",
    r"(?i)\b(api[_-]?key|secret|token|password)\s*=\s*[\"']?[a-zA-Z0-9+/]{32,}[\"']?",
    r"-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY-----",
]

exfil_patterns = [
    r"\bcurl\b.*\b(https?|s3|gs|ssh)\b",
    r"\bwget\b.*\b(https?|s3|gs|ssh)\b",
    r"\bscp\b",
    r"\brsync\b.*\b(e?ssh|@)\b",
    r"\baws\s+s3\b\s+(cp|sync|mv)\b",
    r"\bgsutil\b\s+(cp|rsync|mv)\b",
    r"\brclone\b\s+(copy|sync|move)\b",
    r"\bzip\b.*\b(/data|/datasets|/mnt|/Volumes)\b",
    r"\btar\b.*\b(/data|/datasets|/mnt|/Volumes)\b",
]

confirm_token = os.environ.get("DS_SHERPA_CONFIRM_TOKEN", "--YES-I-KNOW")
confirm_required = [
    r"\bterraform\s+apply\b",
    r"\bkubectl\s+delete\b",
    r"\bgcloud\s+projects\s+delete\b",
    r"\baws\s+s3\s+rm\b",
]

def contains_any(patterns, string):
    for pat in patterns:
        if re.search(pat, string):
            return pat
    return None

danger = contains_any(danger_patterns, cmd)
if danger:
    print(f"[blocked] dangerous command pattern: {danger}", file=sys.stderr)
    sys.exit(2)

confirm = contains_any(confirm_required, cmd)
if confirm and confirm_token not in cmd:
    print(
        "[blocked] high-risk command. Re-run with confirmation token:\n"
        f"  {confirm_token}\n",
        file=sys.stderr
    )
    sys.exit(2)

secret = contains_any(secret_patterns, cmd)
if secret:
    print("[blocked] command appears to contain a secret. Use env vars or a secret manager.", file=sys.stderr)
    sys.exit(2)

exfil = contains_any(exfil_patterns, cmd)
if exfil:
    if os.environ.get("DS_SHERPA_ALLOW_EXFIL") == "1":
        sys.exit(0)
    allowlist = os.environ.get("DS_SHERPA_EXFIL_ALLOWLIST", "localhost,127.0.0.1,0.0.0.0")
    allowlist_file = os.environ.get("DS_SHERPA_EXFIL_ALLOWLIST_FILE", os.path.expanduser("~/.claude/exfil_allowlist"))
    try:
        if os.path.exists(allowlist_file):
            with open(allowlist_file, "r", encoding="utf-8") as f:
                file_items = [line.strip() for line in f if line.strip() and not line.strip().startswith("#")]
            if file_items:
                allowlist = allowlist + "," + ",".join(file_items)
    except Exception as exc:
        print(f"[warn] failed to read allowlist file {allowlist_file}: {exc}", file=sys.stderr)
    if allowlist:
        for item in [s.strip() for s in allowlist.split(",") if s.strip()]:
            pattern = r'(?:^|[:/\s@])' + re.escape(item) + r'(?:$|[:/\s])'
            if re.search(pattern, cmd):
                sys.exit(0)
    print("[blocked] possible data exfiltration pattern detected. Confirm destination and use approved channels.", file=sys.stderr)
    sys.exit(2)

sys.exit(0)
