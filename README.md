# ds-sherpa

A Claude Code plugin for data science workflows: experiments, metrics, SQL, EDA, review, and safety hooks.

## What it does

- **28 skills** across three domains (DS, Quant, Content)
- **9 subagents** (experiment-designer, sql-analyst, data-qa, modeling-lead, quant, ml-engineer, writer, reviewer, ops)
- **23 slash commands** with structured JSON outputs
- **Safety hooks**: blocks dangerous bash commands, detects secrets, prevents data exfiltration, auto-formats and lints after edits

## Install

```bash
# Clone and run the bootstrap script
git clone https://github.com/pitcany/ds-sherpa.git
cd ds-sherpa
bash ds-sherpa.sh ~/.claude/plugins/ds-sherpa
```

Then inside Claude Code:

```
/plugin install ~/.claude/plugins/ds-sherpa
/plugin enable ds-sherpa
```

### Options

```
-v          Verbose output
-d ds,quant Install only specific skill domains (ds, quant, content)
-e          Set up Python virtual environment
-c          Install core DS packages (pandas, numpy, scipy, etc.)
-S          Full DS preset (core + connectors + ML libs)
-q          Install quant/math packages (cvxpy, arch, numba, etc.)
-Q          Quant full preset (core + quant)
-T          Install PyTorch CPU-only
-g          Install PyTorch GPU (set DS_SHERPA_CUDA=cu118|cu121|cu124)
-C          Use conda instead of venv
-w          Create warehouse MCP template
-D          Dry-run
-n          Skip backup
```

## Skills

### DS (`skills/ds/`)

| Skill | Description |
|-------|-------------|
| eda | EDA checklist + hypotheses + falsification |
| metric-check | Metric design audit: definition, sensitivity, guardrails |
| sql | Analytical SQL with grain discipline and validation |
| ab-plan | A/B test plan: hypothesis, metrics, power, SRM |
| readout | Executive experiment readout |
| model-plan | Modeling plan: baselines, features, eval, deployment |
| feature-audit | Feature provenance + leakage/drift risk |
| review | DS code review rubric |
| decision-memo | One-page decision memo (Staff+ style) |
| data-qa | Data QA checklist for pipelines and schemas |
| cohort-analysis | Cohort analysis plan + interpretation |
| anomaly-triage | Root-cause triage workflow |
| data-contracts | Data contracts: schema, SLAs, owners |

### Quant (`skills/quant/`)

| Skill | Description |
|-------|-------------|
| factor-lab | Factor research: signal, IC, decay, turnover, costs |
| risk-check | Risk sanity check: exposures, tails, leverage |
| backtest-plan | Backtest plan: data hygiene, timing, costs |
| trade-memo | Trading memo: thesis, catalysts, sizing, exit |
| options-notes | Options/vol note: payoff, greeks, scenarios |

### Content (`skills/content/`)

| Skill | Description |
|-------|-------------|
| research | Structured research brief with citations |
| summary | Summarize into key points, decisions, actions |
| content-plan | Content strategy: audience, pillars, cadence |
| hook | Generate platform-tailored hooks |
| script | Script with beats, transitions, CTA |
| caption | Titles + captions + CTAs |
| repurpose | Repurpose content across platforms |
| newsletter | Newsletter edition with structure and CTA |
| seo-brief | SEO content brief |
| thumbnail-brief | YouTube thumbnail creative brief |

## Safety

The `guard_bash.py` hook runs before every bash command and blocks:

- **Dangerous commands**: `rm -rf`, `mkfs`, `dd`, `shutdown`, `shred`, destructive git operations
- **Secrets**: AWS keys, API keys, private keys in commands
- **Data exfiltration**: `curl`, `wget`, `scp`, `rsync`, `aws s3 cp` to unapproved destinations

Configure approved destinations:

```bash
# Env var (comma-separated)
export DS_SHERPA_EXFIL_ALLOWLIST="localhost,127.0.0.1,corp.example.com"

# Or file (one per line)
echo "corp.example.com" >> ~/.claude/exfil_allowlist
```

High-risk commands (`terraform apply`, `kubectl delete`) require a confirmation token (default: `--YES-I-KNOW`).

## MCP Servers

Included MCP server configs (in `mcp-servers/ds-mcp.json`):

- BigQuery, GitHub, Playwright, Notion, Supabase, Greptile, Linear

Set up in a repo: run `/ds-mcp-setup` or `/ds-mcp-merge` inside Claude Code.

## Project Configuration

Create a `.claude/CLAUDE.md` in each repo to define metrics, table grains, and conventions:

```
/ds-claude-template
```

## Development

```bash
# Run tests
pytest tests/

# Syntax-check the bootstrap script
bash -n ds-sherpa.sh

# Dry-run install
bash ds-sherpa.sh -v -D /tmp/ds-sherpa-test
```

## License

MIT
