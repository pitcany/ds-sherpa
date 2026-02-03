
---
name: metric-check
description: Metric design audit: definition, sensitivity, guardrails, gaming risk, variance.
---

When to use:
- You need to validate or formalize a metric definition.

Inputs:
- Metric definition or product goal and desired behavior.

Output:
1) Precise definition: numerator/denominator, unit of analysis, attribution window
2) Validity threats: selection bias, survivorship, Simpsons paradox, logging gaps, interference
3) Variance/sensitivity drivers; suggest CUPED/stratification if relevant
4) Guardrails: at least two guardrails + rationale
5) "How it can be gamed" + mitigation
6) Return a cleaned metric spec ready for an experiment doc

