
---
allowed-tools: Task, Bash(python:*), Bash(pip:*), Bash(jq:*), Bash(cat:*)
description: Options/vol note template with structured outputs
---

Inputs:
- Position details, underlyings, tenors, strikes.

Required output format (strict):
```json
{
  "position_summary": "",
  "payoff_profile": "",
  "greeks": {"delta":"", "gamma":"", "vega":"", "theta":""},
  "vol_surface_notes": ["..."],
  "stress_scenarios": ["..."],
  "hedging_notes": ["..."]
}
```
If any fields are unknown, use `null` or empty lists.

