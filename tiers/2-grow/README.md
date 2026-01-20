# Tier 2: Grow

Additions for established projects with CI/CD needs and team coordination.

## When to Upgrade to Tier 2

- Multiple contributors working on the project
- Need for automated CI pipeline
- Complex features requiring structured workflow
- Quality gates becoming important
- Want to audit security and code quality

## What's Added

### Roles

| Role | Purpose |
|------|---------|
| [orchestrator](roles/orchestrator.md) | Coordinates workflow, routes work, handles escalations |
| [triage](roles/triage.md) | Validates issues before planning begins |

### Workflows

| Workflow | Purpose |
|----------|---------|
| [feature](workflows/feature.md) | Full workflow with triage, spec, impl loop, docs, PR |

### CI Templates

Auto-selected based on `docs/tech-stack.md` Runtime:

| Runtime | Template |
|---------|----------|
| Node.js / TypeScript | [ci-node.yml](ci/ci-node.yml) |
| Python | [ci-python.yml](ci/ci-python.yml) |
| Go | [ci-go.yml](ci/ci-go.yml) |

### Skills

| Skill | Purpose |
|-------|---------|
| [security-audit](skills/security-audit/) | Scan for vulnerabilities, secrets, OWASP issues |
| [quality-audit](skills/quality-audit/) | Module sizes, complexity, test coverage |

## Installation

After upgrade, files are added to your project:

```bash
# Files added to .aix/roles/
orchestrator.md
triage.md

# Files added to .aix/workflows/
feature.md

# Files added to .aix/skills/
security-audit/SKILL.md
quality-audit/SKILL.md

# CI template (auto-selected based on tech-stack.md)
# .aix/ci/ci.yml  ← Copy to .github/workflows/ci.yml
```

## Setting Up CI

The upgrade script automatically selects a CI template based on your `docs/tech-stack.md` Runtime field.

1. Copy the generated CI template:
   ```bash
   mkdir -p .github/workflows
   cp .aix/ci/ci.yml .github/workflows/ci.yml
   ```

2. Customize for your project:
   - Adjust runtime version if needed
   - Change package manager (`npm`→`pnpm`, `pip`→`poetry`, etc.)
   - Update script names to match your `package.json` / `Makefile`

3. Commit and push to enable CI

**Manual selection**: If auto-detection fails, all templates are copied to `.aix/ci/`. Choose the right one and rename to `ci.yml`.

## Using New Roles

### Orchestrator

The orchestrator coordinates multi-phase work:

```
User request → Orchestrator decides workflow
                    ↓
          feature workflow: triage → analyst → impl → docs → PR
          quick-fix workflow: impl → docs → PR
```

### Triage

Triage validates issues before work begins:

```
"Investigate issue #123"
    ↓
Triage verifies: reproducible? duplicate? already fixed?
    ↓
If valid → proceed to analyst
If invalid → close with reason
```

## Using Feature Workflow

For substantial changes:

```
"Use the feature workflow to implement search"

1. TRIAGE: Validate the issue
   → User approves or closes

2. ANALYST: Create spec with acceptance criteria
   → User approves or requests changes

3. IMPLEMENTATION LOOP:
   coder → reviewer → tester → (repeat if issues)

4. DOCS: Update documentation if needed

5. PR: Create pull request
   → User approves merge
```

## Using Audit Skills

```bash
# Security audit
/security-audit
/security-audit --quick

# Quality audit
/quality-audit
/quality-audit --coverage
```

## Workflow Decision

| Situation | Workflow |
|-----------|----------|
| New feature | feature |
| Multiple files | feature |
| Needs spec approval | feature |
| Simple bug fix | quick-fix |
| Typo/obvious fix | quick-fix |

## Next Tier

Tier 3 (Scale) adds:
- Worktree support for parallel development
- Compaction hooks for context recovery
- Strategy docs for complex projects
- Task management integration
