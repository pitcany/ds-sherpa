
---
name: eda
description: Fast but rigorous EDA checklist + hypotheses + what would falsify them.
---

When to use:
- You need a fast but rigorous EDA plan or summary.

Inputs:
- Tables/columns, grain, time window, primary metric(s), key segments.
- If missing, ask only for the minimum required.

Output:
1) Data sanity checks (nulls, duplicates, ranges, invariants)
2) Grain verification and join key safety
3) Distribution checks (tails/outliers)
4) Segment breakdowns (top segments + suspicious ones)
5) Time drift checks if time exists
6) Five hypotheses + what evidence would falsify each
7) End with:
   - "Next 3 queries to run"
   - "Top 3 plots to make"
   - "Top 3 risks to conclusions"

