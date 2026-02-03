
---
allowed-tools: Task, Bash(python:*), Bash(pip:*), Bash(jq:*), Bash(cat:*)
description: Quant risk checklist with structured outputs
---

Produce a structured risk checklist.

Inputs:
- Strategy description, exposures, constraints.

Required output format (strict):
```json
{
  "primary_risks": ["..."],
  "tail_scenarios": ["..."],
  "leverage_checks": ["..."],
  "liquidity_checks": ["..."],
  "stress_tests": ["..."],
  "monitoring_metrics": ["..."]
}
```
If any fields are unknown, use `null` or empty lists.

