
---
allowed-tools: Task, Bash(cat:*), Bash(jq:*)
description: SEO brief with structured outputs
---

Inputs:
- Target keyword, audience, intent.

Required output format (strict):
```json
{
  "primary_keyword": "",
  "intent": "",
  "outline": ["..."],
  "faqs": ["..."],
  "internal_links": ["..."],
  "meta_description": ""
}
```
If any fields are unknown, use `null` or empty lists.

