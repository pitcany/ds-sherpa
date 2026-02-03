
---
name: data-qa
description: Data QA checklist for pipelines, schemas, and invariants.
---

When to use:
- You need a data quality audit for pipelines or datasets.

Inputs:
- Dataset, schema, and expected invariants.

Output:
- Schema/contract checks (types, required fields, invariants)
- Freshness/lag validation
- Null/duplicate/outlier checks
- Logging completeness vs source of truth
- Backfill and historical drift review
- Return: a table of checks (status, evidence) + top five risks + next fixes

