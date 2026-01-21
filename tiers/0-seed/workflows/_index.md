# Workflows

Workflows define **how work flows** through phases with approval gates.

## Tier 0 Workflows

| Workflow | When to Use |
|----------|-------------|
| [standard](standard.md) | Default for features and fixes |

## Workflow Selection

```
Is it a simple, clear task?
├─ Yes → Use standard workflow
└─ No → Break it down into simpler tasks
```

## Standard Workflow Overview

```
ANALYZE ──✓──> IMPLEMENT ──✓──> REVIEW ──✓──> COMPLETE
        User          Tests          Issues
        approves      pass           resolved
```

| Phase | Role | Gate |
|-------|------|------|
| Analyze | analyst | User approves spec |
| Implement | coder | Tests pass |
| Review | reviewer | No critical/high issues |
| Complete | - | User approves merge |

## Approval Gates

Every workflow has gates where user approval is required:

1. **After Analysis**: "Is this approach correct?"
2. **Before Commit**: "Ready to commit these changes?"
3. **Before Push**: "Ready to push to remote?"

Gates prevent AI from taking irreversible actions without consent.

## Additional Workflows (Higher Tiers)

| Tier | Workflow | Purpose |
|------|----------|---------|
| 1 | quick-fix | Fast path for trivial fixes (skip full analysis) |
| 2 | feature | Full workflow with triage and multiple review loops |
| 2 | refactor | Infrastructure, tech debt, and architectural changes |

Run `/aix-init upgrade` to add workflows appropriate for your tier.
