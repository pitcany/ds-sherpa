
---
name: feature-audit
description: Feature provenance + leakage/drift risk + inference-time availability audit.
---

When to use:
- You need a feature audit for leakage, drift, and availability risk.

Inputs:
- Feature list and sources.

Output:
- Source of truth for each feature (table/system)
- Refresh cadence and lag
- Inference-time availability (yes/no; alternatives if no)
- Leakage risk (target proxies, post-treatment)
- Drift risk + monitoring suggestions
- Return a table + top five risks + mitigations

