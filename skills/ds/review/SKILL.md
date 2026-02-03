
---
name: review
description: DS code review rubric: correctness, data safety, tests, performance, clarity.
---

When to use:
- You need a DS-focused code or PR review.

Inputs:
- Code/PR context and expected behavior.

Output:
- Correctness (logic, edge cases)
- Data safety (grains, joins, filters, leakage, privacy)
- Reproducibility (seeds, configs, env)
- Tests (unit/integration, invariants)
- Performance (big-O, query cost, vectorization)
- Return a prioritized list of fixes + suggested diffs/snippets

