# Refactor Workflow

Workflow for refactoring, infrastructure changes, and technical improvements that don't introduce new user-facing functionality.

## Overview

```
┌─────────┐     ┌─────────┐     ┌────────────────┐     ┌──────────────┐     ┌─────────┐
│ TRIAGE? │────▶│ ANALYST │────▶│ IMPLEMENTATION │────▶│ DOCS (if any)│────▶│   PR    │
└─────────┘  ✓  └─────────┘  ✓  │      LOOP      │  ✓  └──────────────┘  ✓  └─────────┘
  optional  │               │   └────────────────┘  │                    │
       Orchestrator    User approves           Tests pass           User approves
       decides         approach                                     push & PR
```

## When to Use

- Test reorganization or restructuring
- Code refactoring (no behavior change)
- CI/CD pipeline changes
- Infrastructure/tooling updates
- Dependency upgrades
- Performance optimization
- Tech debt cleanup
- Directory structure changes

## When NOT to Use

Use [feature workflow](./feature.md) instead when:
- Adding new user-facing functionality
- Creating new API endpoints
- Making UI changes
- Changing application behavior
- Adding new integrations

Use [quick-fix workflow](./quick-fix.md) instead when:
- Single-file changes
- Simple, well-understood fixes
- Low-risk updates

---

## Phase 1: Triage (Optional)

**Role**: triage
**Purpose**: Validate scope and check for blockers

> **Orchestrator decides** whether to run triage. Skip for well-defined tasks with clear scope.
> Run triage when: scope is unclear, may have hidden dependencies, or needs investigation.

### When to Skip

- Task has clear acceptance criteria
- Scope is well-defined in task description
- No ambiguity about what needs to change

### When to Run

- Scope is unclear or broad
- May have hidden dependencies
- Need to investigate current state
- Potential conflicts with in-progress work

### Actions (if running)

1. Review task and related context
2. Check for blocking dependencies
3. Identify affected systems/files
4. Verify no conflicts with other work
5. Assess complexity and risk

### Output

```markdown
## Triage Result: PROCEED / BLOCKED / NEEDS_CLARIFICATION

### Scope Assessment
[What's actually involved]

### Dependencies
[Blocking or related work]

### Risk Assessment
- Complexity: [low/medium/high]
- Risk: [low/medium/high]
- Estimated files: [count]

### Recommendation
[Proceed / Wait for X / Clarify Y]
```

---

## Phase 2: Analyst

**Role**: analyst
**Purpose**: Plan the refactor with architectural alignment

> Unlike feature workflow, focus is on **architectural alignment** and **technical correctness**,
> not user-facing requirements.

### Actions

1. **Review architectural guidance**
   - Check relevant docs in `docs/architecture/` or `docs/guides/`
   - Verify alignment with established patterns
   - Identify any conventions to follow

2. **Map the changes**
   - List all files to modify/move/create/delete
   - Identify configuration changes
   - Note any migration steps needed

3. **Define acceptance criteria**
   - Focus on technical correctness
   - Include test coverage expectations
   - Define "done" clearly

4. **Identify risks**
   - Breaking changes
   - CI/CD impacts
   - Rollback strategy

### Output

Create: `.aix/plans/{refactor-name}/plan.md`

```markdown
# Plan: [Refactor Name]

## Task Reference
- Issue: #[id]
- Created: [date]

## Problem Statement
[Why this refactor is needed]

## Architectural Alignment
- [ ] Follows [pattern/convention] from [doc]
- [ ] Consistent with existing [system]
- [ ] No violations of [constraint]

## Change Map

### Files to Move
| From | To |
|------|-----|
| path/old | path/new |

### Files to Modify
| File | Change |
|------|--------|
| path | Description |

### Files to Create
| File | Purpose |
|------|---------|
| path | Description |

### Files to Delete
| File | Reason |
|------|--------|
| path | Replaced by X |

### Configuration Changes
| Config | Change |
|--------|--------|
| file | Description |

## Implementation Steps
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Acceptance Criteria
- [ ] AC1: [Technical requirement]
- [ ] AC2: [Test coverage requirement]
- [ ] AC3: [CI/build requirement]

## Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| [Risk] | [How to handle] |

## Out of Scope
- [Explicitly excluded item]

## Test Plan
- [ ] Existing tests pass
- [ ] New tests for [coverage gap]
- [ ] CI pipeline passes
```

### Approval Gate: After Analyst

```
╔══════════════════════════════════════════════════════════════╗
║  APPROVAL GATE: Plan Complete                                ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  Refactor: [Name]                                            ║
║                                                              ║
║  Scope:                                                      ║
║    - Files to move: [count]                                  ║
║    - Files to modify: [count]                                ║
║    - Configs to update: [count]                              ║
║                                                              ║
║  Architectural Alignment:                                    ║
║    - [Pattern/convention being followed]                     ║
║                                                              ║
║  Options:                                                    ║
║    [A] Approve - proceed to implementation                   ║
║    [B] Request changes                                       ║
║    [C] Reject - different approach needed                    ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

---

## Phase 3: Implementation Loop

**Roles**: coder, reviewer, tester
**Purpose**: Implement, review, and test until quality bar met

### Loop Execution

```
┌─────────────────────────────────────────────────────────────┐
│                    ITERATION N                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  CODER                                                      │
│  ├── Read plan and acceptance criteria                      │
│  ├── Implement changes (or fix feedback from prior loop)    │
│  ├── Run existing tests (ensure no regressions)             │
│  ├── Add new tests if needed                                │
│  └── Commit changes                                         │
│                                                             │
│  REVIEWER                                                   │
│  ├── Check plan compliance                                  │
│  ├── Verify architectural alignment                         │
│  ├── Check for unintended side effects                      │
│  ├── Classify findings by severity                          │
│  └── Output: APPROVED or CHANGES_REQUESTED                  │
│                                                             │
│  TESTER                                                     │
│  ├── Run automated tests                                    │
│  ├── Verify acceptance criteria                             │
│  ├── Check CI pipeline                                      │
│  ├── Classify findings by severity                          │
│  └── Output: PASS or BUGS_FOUND                             │
│                                                             │
│  LOOP CONTROLLER                                            │
│  ├── Aggregate findings                                     │
│  ├── Check exit conditions                                  │
│  └── Decision: EXIT / LOOP / ESCALATE                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Exit Conditions

- **Clean exit**: No critical, high, or medium issues
- **Escalate**: Max iterations reached, no progress, or timeout

---

## Phase 4: Documentation (Conditional)

**Role**: docs
**Purpose**: Update internal documentation if needed

> **No manual verification phase** - refactors don't have UI to verify.
> Skip straight to docs if applicable.

### Mandatory Check

Before deciding whether to skip this phase, **read** the following files (if they exist):
- `docs/roadmap.md`
- `docs/capabilities.md`

If either file references the work being completed, update it. Follow each file's stated conventions (e.g., roadmap may be future-work-only with completed items removed, capabilities may be completed-work-only).

Do not decide "no docs needed" from memory. Read first, then decide.

### When to Run

Check `doc_impact` from analyst plan, **after** the mandatory check above:

| doc_impact | Action |
|------------|--------|
| `none` (verified by reading) | Skip this phase |
| `internal` | Update internal docs (READMEs, guides, architecture docs) |

> For refactors, `doc_impact` is typically `none` or `internal` only.
> External (user-facing) docs are rare for refactors.

### Actions (if running)

1. Update relevant docs:
   - README files
   - Architecture docs
   - Testing guides
   - Developer guides

---

## Phase 5: PR

**Role**: orchestrator
**Purpose**: Push changes and create pull request

### Approval Gate: Before PR

```
╔══════════════════════════════════════════════════════════════╗
║  APPROVAL GATE: Ready for PR                                 ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  Refactor Complete                                           ║
║    - Iterations: [count]                                     ║
║    - Tests: [passed] passed, [failed] failed                 ║
║    - Acceptance Criteria: [x/y] passed                       ║
║    - Critical/High Issues: 0                                 ║
║                                                              ║
║  Docs Updated: [files or "none"]                             ║
║                                                              ║
║  Options:                                                    ║
║    [A] Approve - push and create PR                          ║
║    [B] Request final changes                                 ║
║    [C] Abort                                                 ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

### PR Actions

1. **Rebase onto dev and push**:
   ```bash
   git fetch origin && git rebase origin/dev
   git push -u origin <branch> --force-with-lease
   ```

2. **Create PR** (never merge locally):
   ```bash
   gh pr create --base dev
   ```

3. **After PR merged**:
   - Create tech debt cards for deferred issues
   - Close the original task

---

## Comparison with Other Workflows

| Aspect | Quick-fix | Refactor | Feature |
|--------|-----------|----------|---------|
| Triage | No | Optional | Yes |
| Analyst/Spec | No (task is spec) | Yes (arch focus) | Yes (full spec) |
| Implementation | Yes | Yes | Yes |
| Manual Verify | No | **No** | Optional |
| Docs | Rare | Internal only | Internal + External |
| Typical scope | 1 file | 5-50 files | Varies |
| User-facing | Bug fix | No | Yes |

---

## Example Refactor Session

```markdown
## Task: Reorganize test structure

### Triage: SKIPPED
- Task is well-defined with clear acceptance criteria
- No investigation needed

### Analyst
- Reviewed test taxonomy from testing guide
- Mapped 13 files to move from e2e/ to component/
- Identified config updates needed
- Plan created: .aix/plans/test-reorg/plan.md

### User Approval: APPROVED

### Implementation (2 iterations)
- Iteration 1: Moved files, updated configs
- Reviewer found: M-001 - Missing test file in component/
- Iteration 2: Fixed M-001, added README
- All tests passing

### Docs: Updated __tests__/README.md

### Merge
- Rebased and pushed
- PR #102 created and merged
- No tech debt logged
- Task closed
```

---

## Iteration Limits

| Loop | Max Iterations | On Exceed |
|------|----------------|-----------|
| Coder → Reviewer → Tester | 5 | Escalate to user |

Refactor workflow allows more iterations than standard/quick-fix due to complexity. After 5 iterations without resolution, escalate.

---

## Exit Status

When workflow cannot converge, report using this format:

```
EXIT_STATUS: needs_human_review
REASON: [specific reason]
ATTEMPTS: [number of iterations]
LAST_ISSUES: [list of unresolved issues with severity codes]
```

**Example:**
```
EXIT_STATUS: needs_human_review
REASON: Circular dependency discovered during restructure
ATTEMPTS: 4
LAST_ISSUES: [H-001: Breaking import in moduleA, M-002: Test isolation failure]
```

---

## Verification Checklist

Before marking workflow complete, verify:

- [ ] All tests pass (no regressions)
- [ ] No CRITICAL or HIGH severity issues remain
- [ ] All acceptance criteria from plan are met
- [ ] Architectural alignment verified by reviewer

---

## When Running Under Orchestration

When this workflow is executed by an external orchestrator (e.g., AIX-Factor):

**DO NOT:**
- Check CI status (orchestrator handles this)
- Create or manage PRs (orchestrator handles this)
- Push to remote (orchestrator handles this)
- Check GitHub Actions (orchestrator handles this)

**Focus on:** triage (optional) → analyst → implement loop → docs → commit locally

The orchestrator handles push, PR creation, and external verification.
