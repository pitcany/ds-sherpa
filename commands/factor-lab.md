
---
allowed-tools: Task, Bash(python:*), Bash(pip:*), Bash(jq:*), Bash(cat:*)
description: Factor research checklist with structured outputs
---

Produce a structured factor research checklist.

Inputs:
- Signal hypothesis, universe, and constraints.

Required output format (strict):
```json
{
  "signal_definition": "",
  "universe": "",
  "neutralization": ["..."],
  "data_requirements": ["..."],
  "evaluation_metrics": ["IC", "RankIC", "t-stat"],
  "decay_analysis": ["..."],
  "turnover": "",
  "cost_model": "",
  "backtest_plan": ["..."],
  "robustness_checks": ["..."]
}
```
If any fields are unknown, use `null` or empty lists.

