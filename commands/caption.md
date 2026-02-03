
---
allowed-tools: Task, Bash(cat:*), Bash(jq:*)
description: Titles, captions, and CTAs with structured outputs
---

Inputs:
- Platform, tone, constraints.

Required output format (strict):
```json
{
  "titles": ["..."],
  "captions": {"short":"","medium":"","long":""},
  "ctas": ["..."],
  "hashtags": ["..."]
}
```
If any fields are unknown, use `null` or empty lists.

