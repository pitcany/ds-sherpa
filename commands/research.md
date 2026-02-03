
---
allowed-tools: Task, WebSearch, WebFetch, Bash(python:*), Bash(jq:*), Bash(cat:*)
description: Research brief with structured outputs and citations
---

Produce a structured research brief with citations where possible.

Inputs:
- Research question, scope, recency constraints.

Required output format (strict):
```json
{
  "question": "",
  "scope": "",
  "sources": [{"title":"","url":"","type":""}],
  "findings": [{"theme":"","summary":"","evidence":["..."]}],
  "caveats": ["..."],
  "recommendation": ""
}
```
If any fields are unknown, use `null` or empty lists.

