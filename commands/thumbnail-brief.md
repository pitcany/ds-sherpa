
---
allowed-tools: Task, Bash(cat:*), Bash(jq:*)
description: Thumbnail creative brief with structured outputs
---

Inputs:
- Topic, audience, style constraints.

Required output format (strict):
```json
{
  "concepts": [{"title":"","text":"","composition":""}],
  "ab_variants": ["..."]
}
```
If any fields are unknown, use `null` or empty lists.

