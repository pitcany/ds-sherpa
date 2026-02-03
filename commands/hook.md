
---
allowed-tools: Task, Bash(cat:*), Bash(jq:*)
description: Generate hooks with structured outputs
---

Inputs:
- Platform, topic, tone.

Required output format (strict):
```json
{
  "platform": "",
  "topic": "",
  "hooks": ["..."]
}
```
If any fields are unknown, use `null` or empty lists.

