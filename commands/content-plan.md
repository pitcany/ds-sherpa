
---
allowed-tools: Task, Bash(cat:*), Bash(jq:*)
description: Content strategy plan with structured outputs
---

Inputs:
- Audience, goal, platforms.

Required output format (strict):
```json
{
  "audience": "",
  "angle": "",
  "pillars": ["..."],
  "ideas": [{"title":"","hook":""}],
  "cadence": "",
  "distribution": ["..."]
}
```
If any fields are unknown, use `null` or empty lists.

