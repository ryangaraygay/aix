# Tier 1: Sprout

Additions for growing projects where patterns are emerging and quality starts to matter more.

## When to Upgrade to Tier 1

- You've used Tier 0 successfully
- Test coverage is becoming important
- You want automated quality checks
- Documentation needs attention
- You're committing more frequently

## What's Added

### Roles

| Role | Purpose |
|------|---------|
| [tester](roles/tester.md) | Dedicated test writing and verification |
| [docs](roles/docs.md) | Documentation updates and maintenance |

### Workflows

| Workflow | Purpose |
|----------|---------|
| [quick-fix](workflows/quick-fix.md) | Streamlined flow for simple changes |

### Hooks

| Hook | Purpose |
|------|---------|
| [pre-commit](hooks/pre-commit) | File size limits, no focused tests, debug statement warnings |

### Skills

| Skill | Purpose |
|-------|---------|
| [test](skills/test/) | Run test suite with framework detection |
| [commit](skills/commit/) | Create well-formatted conventional commits |

## Installation

The upgrade process copies these files to your project:

```bash
# Files added to .aix/roles/
tester.md
docs.md

# Files added to .aix/workflows/
quick-fix.md

# Files added to .aix/skills/
test/SKILL.md
commit/SKILL.md

# Files added to .husky/ (or similar)
pre-commit
```

## Using New Roles

After upgrade, you can use the tester and docs roles in your workflow:

```
Standard workflow:
  analyst → coder → reviewer → tester → complete

With docs (if documentation affected):
  analyst → coder → reviewer → tester → docs → complete
```

## Using Quick-Fix

For small, obvious changes:

```
"Use the quick-fix workflow to fix this typo"
```

Skips the analysis phase, goes straight to implement → review → complete.

## Using New Skills

```
/test           # Run all tests
/test --watch   # Watch mode

/commit         # Auto-generate commit message
/commit "msg"   # Use custom message
```

## Pre-commit Hooks

The pre-commit hook checks:

1. **File size** - Warns at 300 lines, blocks at 500
2. **Focused tests** - Blocks `.only`, `fit`, `fdescribe`
3. **Debug statements** - Warns about `console.log`, `debugger`
4. **TODOs** - Info about TODO/FIXME markers

### Setup

After upgrade, make the hook executable:

```bash
chmod +x .husky/pre-commit

# If using husky npm package:
npx husky add .husky/pre-commit "./.aix/hooks/pre-commit"
```

## Next Tier

Tier 2 (Grow) adds:
- GitHub Actions CI
- orchestrator and triage roles
- Feature workflow with full phases
- Audit skills
