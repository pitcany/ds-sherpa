
---
name: anomaly-triage
description: Triage anomalies with root-cause workflow and checks.
---

When to use:
- Metrics look wrong and you need a root-cause triage plan.

Inputs:
- Metric definition, timeframe, and recent changes.

Output:
- Likely root causes by layer (logging, ETL, feature, model, product)
- Sanity queries (counts, join fanout, time drift)
- Rollback/mitigation steps
- Confidence and next actions
- Return a short incident-style report

