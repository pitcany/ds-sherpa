
---
allowed-tools: Bash(mv:*), Bash(cat:*), Bash(jq:*)
description: Merge DS MCP template into existing mcp.json without overwriting existing servers
---

If `mcp.json` exists, merge in ds-sherpa MCPs, keeping existing entries on conflict.

Inputs:
- Existing `mcp.json` in the repo.

Steps:
1) Backup: `BACKUP=mcp.json.backup.$(date +%Y%m%d_%H%M%S) && mv mcp.json "$BACKUP"`
2) Merge with jq (keep existing):
   - `jq -s ".[0].mcpServers as \$base | .[1].mcpServers as \$tmpl | {mcpServers: (\$tmpl + \$base)}" \
      "$BACKUP" "$CLAUDE_PLUGIN_ROOT/mcp-servers/ds-mcp.json" > mcp.json`
3) Review and remove MCPs you do not need.

Output:
- Updated `mcp.json` with merged MCP servers.

