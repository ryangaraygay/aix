# Audit Framework

A systematic approach to automated codebase audits covering security, quality, performance, and specialized domains.

## Overview

Audit skills provide automated analysis of your codebase against defined standards. They can be invoked manually or integrated into CI pipelines for continuous verification.

```
┌─────────────────────────────────────────────────────────────────┐
│                        AUDIT FRAMEWORK                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │  Security   │  │   Quality   │  │ Performance │             │
│  │   Audit     │  │    Audit    │  │   Audit     │  CORE       │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │Accessibility│  │  Resilience │  │   Privacy   │ SPECIALIZED │
│  │   Audit     │  │    Audit    │  │   Audit     │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐                               │
│  │  Cognitive  │  │   Delight   │               BRAND/UX       │
│  │   Audit     │  │    Audit    │                               │
│  └─────────────┘  └─────────────┘                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Audit Categories

### Core Audits (Tier 2)

Essential for any project. Run these regularly.

| Audit | Purpose | Tier |
|-------|---------|------|
| **security-audit** | Dependencies, secrets, OWASP Top 10 | 2-grow |
| **quality-audit** | Module sizes, complexity, test coverage | 2-grow |

### Specialized Audits (Tier 3)

Domain-specific audits for mature projects.

| Audit | Purpose | Tier |
|-------|---------|------|
| **performance-audit** | Bundle sizes, API latency, DB efficiency | 3-scale |
| **accessibility-audit** | WCAG AA compliance, keyboard nav, focus | 3-scale |
| **resilience-audit** | Offline support, state recovery, error boundaries | 3-scale |
| **privacy-audit** | PII detection, data retention, local-first | 3-scale |
| **cognitive-audit** | UI complexity, decision fatigue, jargon | 3-scale |
| **delight-audit** | Brand voice, empty states, error messages | 3-scale |

## Creating an Audit Skill

### SKILL.md Template

```yaml
---
name: {domain}-audit
description: {One-line description of what this audit checks}
compatibility: {Required tools, e.g., "Requires pnpm, eslint"}
metadata:
  invocation: both  # user | proactive | both
  inputs: |
    - scope: string (optional, all|backend|frontend, default: all)
    - quick: boolean (optional, skip heavy checks, default: false)
  outputs: |
    - report: string (markdown format summary)
---

# {Domain} Audit

{Brief description of the audit's purpose}

## Features

- **{Check 1}**: {What it verifies}
- **{Check 2}**: {What it verifies}
- **{Check N}**: {What it verifies}

## Usage

```bash
./scripts/{domain}-audit.sh
```

### Options

- `--scope <backend|frontend|all>`: Limit audit to specific component.
- `--quick`: Run only fast checks.
- `--fix`: Attempt auto-fixes where possible.

## Prerequisites

1. {Required tool 1}
2. {Required tool 2}

## Output Format

{Description of report structure}
```

### Script Template

```bash
#!/bin/bash
set -euo pipefail

SCOPE="${1:-all}"
QUICK=false
FIX=false

# Parse options
while [[ $# -gt 0 ]]; do
  case $1 in
    --scope) SCOPE="$2"; shift 2 ;;
    --quick) QUICK=true; shift ;;
    --fix) FIX=true; shift ;;
    *) shift ;;
  esac
done

echo "## {Domain} Audit"
echo ""
echo "Scope: $SCOPE"
echo "Quick: $QUICK"
echo ""

# Check 1
echo "### {Check 1}"
# ... implementation

# Check 2
echo "### {Check 2}"
# ... implementation

echo ""
echo "## Summary"
echo ""
echo "- Issues found: X"
echo "- Auto-fixed: Y"
```

## Integration Patterns

### CI Integration

Run audits on every PR:

```yaml
# .github/workflows/audit.yml
name: Audit
on: [pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/security-audit.sh --quick

  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/quality-audit.sh
```

### Scheduled Audits

Run comprehensive audits weekly:

```yaml
# .github/workflows/weekly-audit.yml
name: Weekly Audit
on:
  schedule:
    - cron: '0 9 * * 1'  # Monday 9am

jobs:
  full-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          ./scripts/security-audit.sh
          ./scripts/quality-audit.sh
          ./scripts/performance-audit.sh
```

### Pre-commit Hook

Run quick checks before commit:

```bash
# .husky/pre-commit
./scripts/security-audit.sh --quick || exit 1
```

## Severity Levels

Audits should classify findings by severity:

| Level | Description | Action |
|-------|-------------|--------|
| **CRITICAL** | Security vulnerability, data loss risk | Block merge |
| **HIGH** | Significant issue affecting users | Fix before merge |
| **MEDIUM** | Should be addressed soon | Create task |
| **LOW** | Minor improvement opportunity | Optional |

## Report Format

All audits should output consistent markdown reports:

```markdown
## {Audit Name}

**Scope:** {scope}
**Date:** {timestamp}

### {Category 1}

| Finding | Severity | Location |
|---------|----------|----------|
| {Issue} | HIGH | {file:line} |

### {Category 2}

✅ All checks passed

### Summary

- **Critical:** 0
- **High:** 1
- **Medium:** 3
- **Low:** 5

### Recommendations

1. {Priority action}
2. {Secondary action}
```

## Best Practices

1. **Start with core audits** - Security and quality cover most needs
2. **Run quick mode in CI** - Full audits are for scheduled runs
3. **Fix critical/high immediately** - Don't let them accumulate
4. **Track medium as tasks** - Integrate with your task management
5. **Review low periodically** - Batch them in maintenance sprints
