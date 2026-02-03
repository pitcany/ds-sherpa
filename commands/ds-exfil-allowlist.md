---
allowed-tools: Bash(mkdir:*), Bash(cp:*), Bash(ls:*), Bash(cat:*)
description: Install an exfil allowlist template (~/.claude/exfil_allowlist)
---

Create or update your exfil allowlist:
Inputs:
- None.

1) `mkdir -p ~/.claude`
2) `cp "$CLAUDE_PLUGIN_ROOT/templates/exfil_allowlist.txt" ~/.claude/exfil_allowlist`
3) Edit the file with approved domains/paths.

Output:
- `~/.claude/exfil_allowlist` with approved destinations.
