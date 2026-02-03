
---
allowed-tools: Task, Bash(python:*), Bash(pip:*), Bash(jq:*), Bash(cat:*)
description: Backtest plan template with structured outputs
---

Inputs:
- Strategy description, data, constraints.

Required output format (strict):
```json
{
  "universe": "",
  "point_in_time_data": true,
  "signal_timing": "",
  "transaction_costs": "",
  "constraints": ["..."],
  "validation": ["walk-forward", "sensitivity"],
  "reporting": ["..."],
  "red_flags": ["..."]
}
```
If any fields are unknown, use `null` or empty lists.

