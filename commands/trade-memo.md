
---
allowed-tools: Task, Bash(python:*), Bash(pip:*), Bash(jq:*), Bash(cat:*)
description: Trading memo template with structured outputs
---

Inputs:
- Thesis, entry/exit criteria, risks.

Required output format (strict):
```json
{
  "thesis": "",
  "entry_triggers": ["..."],
  "sizing": "",
  "exit_plan": "",
  "risks": ["..."],
  "invalidate_conditions": ["..."]
}
```
If any fields are unknown, use `null` or empty lists.

