---
allowed-tools: Bash(mkdir:*), Bash(cp:*), Bash(ls:*), Bash(cat:*)
description: Create a project-level .claude/CLAUDE.md template for DS workflows
---

Create a project-level guide:
Inputs:
- None.

1) `mkdir -p .claude`
2) `cp "$CLAUDE_PLUGIN_ROOT/templates/CLAUDE.md" .claude/CLAUDE.md`
3) Fill in metrics, grains, and invariants.

Output:
- `.claude/CLAUDE.md` ready to customize.
