
---
allowed-tools: Task, Bash(python:*), Bash(pip:*), Bash(jq:*), Bash(cat:*)
description: EDA summary with structured outputs (hypotheses + plots + risks)
---

Produce an EDA brief with strictly structured output.

Inputs:
- Dataset name, grain, time window, and key segments.

Required output format (strict):
```json
{
  "dataset": "<name>",
  "grain": "<unit>",
  "time_window": "<start..end>",
  "segments": ["..."],
  "distribution_checks": [{"column":"", "notes":""}],
  "outliers": [{"column":"", "example":"", "impact":""}],
  "drift_checks": [{"column":"", "trend":""}],
  "hypotheses": [{"hypothesis":"", "falsifier":""}],
  "top_plots": ["..."],
  "top_risks": ["..."],
  "next_queries": ["..."]
}
```

If any fields are unknown, include them with `null` and add to `top_risks`.

