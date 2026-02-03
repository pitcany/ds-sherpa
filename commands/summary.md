
---
allowed-tools: Task, Bash(cat:*), Bash(jq:*)
description: Summarize content into key points, decisions, and actions
---

Inputs:
- Source text or notes.

Required output format (strict):
```json
{
  "key_points": ["..."],
  "decisions": ["..."],
  "open_questions": ["..."],
  "actions": ["..."]
}
```
If any fields are unknown, use `null` or empty lists.

