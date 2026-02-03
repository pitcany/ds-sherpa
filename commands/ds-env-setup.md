
---
allowed-tools: Bash(python:*), Bash(pip:*), Bash(uv:*), Bash(rye:*), Bash(ls:*), Bash(cat:*)
description: Create or refresh a Python DS environment for this repo
---

Prefer local venv in repo root:
Inputs:
- Optional `requirements.txt` or `pyproject.toml`.

1) `python3 -m venv .venv`
2) `source .venv/bin/activate`
3) `python -m pip install --upgrade pip setuptools wheel`
4) If `requirements.txt` exists: `pip install -r requirements.txt`
5) If `pyproject.toml` exists: `pip install -e .` or use your toolchain (uv/poetry/rye).
6) Register a kernel (optional): `python -m ipykernel install --user --name <env-name>`

Output:
- A local environment ready for DS work.

