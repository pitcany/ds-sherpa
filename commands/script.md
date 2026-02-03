
---
allowed-tools: Task, Bash(cat:*), Bash(jq:*)
description: Script outline and full draft with structured outputs
---

Inputs:
- Platform, length, audience, goal.

Required output format (strict):
```json
{
  "platform": "",
  "length": "",
  "outline": ["..."],
  "script": "",
  "ctas": ["..."]
}
```
If any fields are unknown, use `null` or empty lists.

