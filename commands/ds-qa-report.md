
---
allowed-tools: Task, Bash(python:*), Bash(pip:*), Bash(jq:*), Bash(cat:*)
description: Data QA checklist with structured outputs for DS decisions
---

Produce a structured QA report for a dataset or query result.

Inputs:
- Dataset name, grain, time window, and checks performed.

Required output format (strict):
```json
{
  "dataset": "<name>",
  "grain": "<unit>",
  "time_window": "<start..end>",
  "row_count": <int>,
  "null_checks": [{"column":"", "null_pct":0.0}],
  "duplicate_checks": [{"key":"", "dup_count":0}],
  "range_checks": [{"column":"", "min":0, "max":0}],
  "invariant_checks": [{"rule":"", "status":"pass|fail"}],
  "schema_drift": [{"column":"", "change":"added|removed|type_changed"}],
  "warnings": ["..."],
  "next_queries": ["..."]
}
```

If any fields are unknown, include them with `null` and add a warning.

