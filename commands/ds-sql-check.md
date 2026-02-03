
---
allowed-tools: Task, Bash(psql:*), Bash(mysql:*), Bash(sqlcmd:*), Bash(duckdb:*), Bash(sqlite3:*)
description: Validate SQL grain and joins with quick sanity checks
---

Use this when reviewing or writing analytical SQL.

Inputs:
- Query text and intended grain.

Checklist:
1) State the intended grain in a comment at the top of the query.
2) Add a row-count sanity check per CTE.
3) Check key uniqueness before joins.
4) After joins, compare row counts and distinct keys to catch fanout.
5) Add a small sample (`LIMIT 100`) with key columns for spot checks.

Output:
- A checklist you can apply to the query.

