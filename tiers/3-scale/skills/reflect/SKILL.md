---
name: reflect
description: Session retrospective - analyze issues encountered, identify anti-patterns, propose improvements to roles/workflows/config.
compatibility: Requires git for change analysis
mode: aix-local-only
metadata:
  invocation: user
  inputs: |
    - scope: string (optional, session|sprint|release, default: session)
    - focus: string (optional, area to analyze - workflow|role|config|all)
    - output: string (optional, report|proposals|both, default: both)
  outputs: |
    - report: string (markdown analysis of issues and patterns)
    - proposals: array (specific improvement suggestions)
---

# Reflect

Conduct a retrospective analysis of recent work to identify improvements.

> **Mode**: AIX-local only. Requires interactive discussion with user about
> what went well, what didn't, and what to improve.

## Purpose

Use this skill when:
- Ending a significant work session
- After completing a feature or sprint
- When the same issues keep recurring
- To improve the AI-human collaboration workflow

## What It Analyzes

### Session Artifacts

| Source | What's Analyzed |
|--------|-----------------|
| Git history | Commit patterns, reverts, fix-after-fix sequences |
| PR comments | Review friction, back-and-forth iterations |
| Test results | Flaky tests, coverage gaps, test-after-code |
| Handoff files | Compaction recovery issues, context loss |
| Todo lists | Abandoned tasks, scope creep, priority shifts |

### Pattern Detection

| Anti-Pattern | Detection Signal | Improvement Area |
|--------------|------------------|------------------|
| Fix-after-fix | Multiple commits fixing same area | Review depth |
| Scope creep | PRs with unrelated changes | Planning rigor |
| Test gaps | Coverage drops in changed files | TDD enforcement |
| Context loss | Repeated questions after compaction | Handoff quality |
| Approval delays | Long PR review times | Review workflow |

## Execution

### Interactive Mode

```bash
# Full session retrospective
./scripts/reflect.sh

# Focus on specific area
./scripts/reflect.sh --focus workflow

# Generate proposals only (skip analysis)
./scripts/reflect.sh --output proposals
```

### Manual Steps

1. **Gather data**
   ```bash
   git log --oneline --since="8 hours ago"
   git diff --stat HEAD~10..HEAD
   gh pr list --state merged --limit 5
   ```

2. **Identify patterns**
   - Count reverts and fix commits
   - Review PR iteration counts
   - Check test coverage trends

3. **Discuss with user**
   - What felt smooth?
   - What caused friction?
   - What would you do differently?

4. **Generate proposals**
   - Specific, actionable improvements
   - Classify by effort (quick/medium/large)
   - Prioritize by impact

## Example Output

```markdown
## Session Retrospective

**Scope:** Last 6 hours
**Commits:** 23
**PRs Merged:** 2

### What Went Well

- TDD discipline maintained (tests before code)
- Clean PR separation (auth vs. UI changes)
- Good use of Task tool for delegation

### Issues Identified

| Issue | Occurrences | Impact |
|-------|-------------|--------|
| Context loss after compaction | 2 | Medium |
| Reviewer found issues coder missed | 3 | High |
| Test flakiness in CI | 1 | Low |

### Anti-Pattern Analysis

**Fix-after-fix detected in `src/auth/`**
- 4 commits in sequence: feat, fix, fix, fix
- Root cause: Incomplete spec in analyst phase
- Recommendation: Add edge case checklist to analyst role

**Scope creep in PR #127**
- PR description: "Add login"
- Actual changes: Login + logout + session timeout
- Recommendation: Enforce single-responsibility PRs

### Proposals

#### Quick Wins (< 1 hour)

1. **Add edge case section to analyst template**
   - File: `roles/analyst.md`
   - Change: Add "Edge Cases" checklist
   - Impact: Reduce fix-after-fix pattern

2. **Update handoff with test status**
   - File: `hooks/pre-compact.sh`
   - Change: Include last test run result
   - Impact: Better compaction recovery

#### Medium Effort (1-4 hours)

3. **Create PR scope validator**
   - New hook: `validate-pr-scope.sh`
   - Detects PRs with mixed concerns
   - Impact: Enforce single-responsibility

### User Confirmation Required

These proposals require your approval before implementation:

- [ ] Proposal 1: Add edge case section
- [ ] Proposal 2: Update handoff with test status
- [ ] Proposal 3: Create PR scope validator

Implement approved proposals? [Select numbers or 'all']:
```

## Output Files

| File | Purpose |
|------|---------|
| `.aix/state/retrospectives/YYYY-MM-DD.md` | Analysis report |
| `.aix/state/proposals/pending.md` | Unapproved proposals |
| `.aix/state/proposals/implemented.md` | Completed improvements |

## Proposal Format

```yaml
proposal:
  id: prop-001
  title: Add edge case section to analyst template
  area: role
  effort: quick
  impact: high
  file: roles/analyst.md
  change: |
    Add "## Edge Cases" section with:
    - Error states
    - Boundary conditions
    - Concurrent access
    - Network failures
  rationale: |
    3 fix-after-fix sequences in last session could have been
    prevented with upfront edge case analysis.
```

## Integration

### With Wrap-Up Skill

The reflect skill can be invoked automatically by wrap-up:

```bash
# wrap-up detects significant session, suggests reflect
wrap-up: "Significant session detected (23 commits, 2 PRs).
         Run /reflect for retrospective analysis?"
```

### With Handoff

Approved proposals are tracked in handoff for implementation:

```markdown
## Pending Proposals
- [ ] prop-001: Add edge case section (approved 2025-01-20)
```

## See Also

- [Wrap-Up Skill](../../2-grow/skills/wrap-up/SKILL.md) - Session end check
- [Analyst Role](../../0-seed/roles/analyst.md) - Planning improvements
- [Reviewer Role](../../0-seed/roles/reviewer.md) - Review improvements
