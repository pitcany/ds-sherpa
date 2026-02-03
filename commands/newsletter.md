
---
allowed-tools: Task, Bash(cat:*), Bash(jq:*)
description: Newsletter draft with structured outputs
---

Inputs:
- Topic, audience, tone, length.

Required output format (strict):
```json
{
  "subject_lines": ["..."],
  "lead": "",
  "main_content": "",
  "key_takeaways": ["..."],
  "cta": ""
}
```
If any fields are unknown, use `null` or empty lists.

