
---
allowed-tools: Bash(cp:*), Bash(ln:*), Bash(mv:*), Bash(ls:*), Bash(cat:*)
description: Set up project-level MCP config for DS/ML (copy or symlink template)
---

Goal: enable DS/ML MCPs for THIS repo by creating `mcp.json`.

Inputs:
- None.

Steps:
1) If `mcp.json` exists, back it up:
   - `mv mcp.json mcp.json.backup.$(date +%Y%m%d_%H%M%S)`
2) Copy the ds-sherpa template:
   - `cp "$CLAUDE_PLUGIN_ROOT/mcp-servers/ds-mcp.json" ./mcp.json`
   - or `ln -sf "$CLAUDE_PLUGIN_ROOT/mcp-servers/ds-mcp.json" ./mcp.json`
3) Open `mcp.json` and delete MCPs you do not need.
4) Add required env vars (e.g., `GREPTILE_API_KEY`, `GITHUB_MCP_PAT`) before use.

Output:
- A project-level `mcp.json` ready to edit.

