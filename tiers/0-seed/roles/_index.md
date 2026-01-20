# Roles

Roles define **who does what** in the aix framework. Each role has specific responsibilities and tool access.

## Tier 0 Roles

| Role | Purpose | Can Write Code? |
|------|---------|-----------------|
| [analyst](analyst.md) | Plan and architect solutions | No |
| [coder](coder.md) | Implement according to spec | Yes |
| [reviewer](reviewer.md) | Review quality and compliance | No |

## Role Flow

```
User Request
    │
    ▼
┌─────────┐     ┌─────────┐     ┌──────────┐
│ Analyst │ ──▶ │  Coder  │ ──▶ │ Reviewer │
└─────────┘     └─────────┘     └──────────┘
   Spec            Code           Review
                     │               │
                     └───────────────┘
                      (if issues found)
```

## Why Role Separation?

1. **Quality**: The same "mind" that wrote code is blind to its flaws
2. **Focus**: Each role does one thing well
3. **Audit trail**: Clear handoffs for debugging

## Tool Access by Role

| Tool | Analyst | Coder | Reviewer |
|------|---------|-------|----------|
| Read | ✅ | ✅ | ✅ |
| Write | ❌ | ✅ | ❌ |
| Edit | ❌ | ✅ | ❌ |
| Bash | ✅ | ✅ | ✅ |
| Grep | ✅ | ✅ | ✅ |
| Glob | ✅ | ✅ | ✅ |

## Additional Roles (Higher Tiers)

These roles are added as your project grows:

| Tier | Role | Purpose |
|------|------|---------|
| 1 | tester | Dedicated test writing and verification |
| 1 | docs | Documentation updates |
| 2 | orchestrator | Coordinate multi-phase workflows |
| 2 | triage | Validate issues before work begins |
| 3 | debug | Complex bug investigation |
| 3 | product-designer | UX and product spec refinement |

Run `/aix-init upgrade` to add roles appropriate for your tier.
