
---
name: sql
description: Generate safe, readable analytical SQL with validation and grain discipline.
---

When to use:
- You need analytical SQL with strong grain and validation discipline.

Inputs:
- Intended grain, primary keys, join keys, timestamps, filters.
- If missing, ask only for these.

Output:
- SQL with explicit CTEs and grain stated in a comment
- Join safety (warn about many-to-many risk)
- Intentional filtering (call out implicit filters)
- Validation section: row counts, key uniqueness checks, spot checks

